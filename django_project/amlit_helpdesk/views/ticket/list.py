__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '27/08/21'

from copy import deepcopy
from django.conf import settings
from django.contrib.auth import get_user_model
from django.contrib.auth.decorators import login_required
from django.db.models import Q
from django.http import HttpResponseRedirect, JsonResponse
from django.shortcuts import render
from django.utils.translation import ugettext as _

from rest_framework import status
from rest_framework.decorators import api_view

from helpdesk.user import HelpdeskUser
from helpdesk.models import (
    Ticket, SavedSearch, KBItem
)
from helpdesk.query import query_to_base64
from amlit_helpdesk.query import Query

User = get_user_model()


@login_required
def ticket_list(request):
    context = {}

    huser = HelpdeskUser(request.user)

    # Query_params will hold a dictionary of parameters relating to
    # a query, to be saved if needed:
    query_params = {
        'filtering': {},
        'filtering_or': {},
        'sorting': None,
        'sortreverse': False,
        'search_string': '',
    }
    default_query_params = {
        'sorting': 'created',
        'search_string': '',
        'sortreverse': False,
    }

    # If the user is coming from the header/navigation search box, lets' first
    # look at their query to see if they have entered a valid ticket number. If
    # they have, just redirect to that ticket number. Otherwise, we treat it as
    # a keyword search.

    if request.GET.get('search_type', None) == 'header':
        query = request.GET.get('q')
        filter = None
        if query.find('-') > 0:
            try:
                queue, id = Ticket.queue_and_id_from_query(query)
                id = int(id)
            except ValueError:
                id = None

            if id:
                filter = {'queue__slug': queue, 'id': id}
        else:
            try:
                query = int(query)
            except ValueError:
                query = None

            if query:
                filter = {'id': int(query)}

        if filter:
            try:
                ticket = huser.get_tickets_in_queues().get(**filter)
                return HttpResponseRedirect(ticket.staff_url)
            except Ticket.DoesNotExist:
                # Go on to standard keyword searching
                pass

    if not {'queue', 'assigned_to', 'status', 'q', 'sort', 'sortreverse', 'kbitem'}.intersection(request.GET):
        # Fall-back if no querying is being done
        query_params = deepcopy(default_query_params)
    else:
        filter_in_params = [
            ('queue', 'queue__id__in'),
            ('assigned_to', 'assigned_to__id__in'),
            ('status', 'status__in'),
            ('kbitem', 'kbitem__in'),
        ]
        filter_null_params = dict([
            ('queue', 'queue__id__isnull'),
            ('assigned_to', 'assigned_to__id__isnull'),
            ('status', 'status__isnull'),
            ('kbitem', 'kbitem__isnull'),
        ])
        for param, filter_command in filter_in_params:
            if not request.GET.get(param) is None:
                patterns = request.GET.getlist(param)
                try:
                    pattern_pks = [int(pattern) for pattern in patterns]
                    if -1 in pattern_pks:
                        query_params['filtering_or'][filter_null_params[param]] = True
                    else:
                        query_params['filtering_or'][filter_command] = pattern_pks
                    query_params['filtering'][filter_command] = pattern_pks
                except ValueError:
                    pass

        date_from = request.GET.get('date_from')
        if date_from:
            query_params['filtering']['created__gte'] = date_from

        date_to = request.GET.get('date_to')
        if date_to:
            query_params['filtering']['created__lte'] = date_to

        # KEYWORD SEARCHING
        q = request.GET.get('q', '')
        context['query'] = q
        query_params['search_string'] = q

        # SORTING
        sort = request.GET.get('sort', None)
        if sort not in ('status', 'assigned_to', 'created', 'title', 'queue', 'priority', 'kbitem'):
            sort = 'created'
        query_params['sorting'] = sort

        sortreverse = request.GET.get('sortreverse', None)
        query_params['sortreverse'] = sortreverse

    urlsafe_query = query_to_base64(query_params)

    Query(huser, base64query=urlsafe_query).refresh_query()

    user_saved_queries = SavedSearch.objects.filter(Q(user=request.user) | Q(shared__exact=True))

    search_message = ''
    if query_params['search_string'] and settings.DATABASES['default']['ENGINE'].endswith('sqlite'):
        search_message = _(
            '<p><strong>Note:</strong> Your keyword search is case sensitive '
            'because of your database. This means the search will <strong>not</strong> '
            'be accurate. By switching to a different database system you will gain '
            'better searching! For more information, read the '
            '<a href="http://docs.djangoproject.com/en/dev/ref/databases/#sqlite-string-matching">'
            'Django Documentation on string matching in SQLite</a>.')

    kbitem_choices = [(item.pk, str(item)) for item in KBItem.objects.all()]

    return render(request, 'helpdesk/ticket_list.html', dict(
        context,
        default_tickets_per_page=request.user.usersettings_helpdesk.tickets_per_page,
        user_choices=User.objects.filter(is_active=True, is_staff=True),
        kb_items=KBItem.objects.all(),
        queue_choices=huser.get_queues(),
        status_choices=Ticket.STATUS_CHOICES,
        kbitem_choices=kbitem_choices,
        urlsafe_query=urlsafe_query,
        user_saved_queries=user_saved_queries,
        query_params=query_params,
        from_saved_query=None,
        saved_query=None,
        search_message=search_message,
    ))


@login_required
@api_view(['GET'])
def datatables_ticket_list(request, query):
    """
    Datatable on ticket_list.html uses this view from to get objects to display
    on the table. query_tickets_by_args is at lib.py, DatatablesTicketSerializer is in
    serializers.py. The serializers and this view use django-rest_framework methods
    """
    query = Query(HelpdeskUser(request.user), base64query=query)
    result = query.get_datatables_context(**request.query_params)
    return JsonResponse(result, status=status.HTTP_200_OK)


@login_required
@api_view(['GET'])
def timeline_ticket_list(request, query):
    query = Query(HelpdeskUser(request.user), base64query=query)
    return JsonResponse(query.get_timeline_context(), status=status.HTTP_200_OK)
