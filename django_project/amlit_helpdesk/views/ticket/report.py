__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '17/09/21'

from datetime import timedelta
from django.shortcuts import render, HttpResponseRedirect, reverse
from django.utils.translation import ugettext as _

from helpdesk.user import HelpdeskUser
from helpdesk.models import Ticket, Queue
from helpdesk.lib import format_time_spent
from helpdesk.views.staff import (
    calc_basic_ticket_stats, load_saved_query, QueryLoadError)
from helpdesk.query import query_to_base64, get_query_class
from amlit_helpdesk.query import get_user_tickets

Query = get_query_class()


def time_spent(tickets):
    total = timedelta(0)
    for val in tickets.all():
        if val.time_spent:
            total = total + val.time_spent
    return total


def dedicated_time(tickets):
    total = timedelta(0)
    for val in tickets.all():
        if val.expected_time:
            total = total + val.expected_time
    return total


def report_index(request):
    tickets = get_user_tickets(request.user)
    number_tickets = tickets.count()
    saved_query = request.GET.get('saved_query', None)

    user_queues = HelpdeskUser(request.user).get_queues()
    tickets = tickets.filter(queue__in=user_queues)
    basic_ticket_stats = calc_basic_ticket_stats(tickets)

    # The following query builds a grid of queues & ticket statuses,
    # to be displayed to the user. EG:
    #          Open  Resolved
    # Queue 1    10     4
    # Queue 2     4    12
    Queues = user_queues if user_queues else Queue.objects.all()

    dash_tickets = []
    for queue in Queues:
        queue_tickets = tickets.filter(queue=queue)
        dash_ticket = {
            'queue': queue.id,
            'name': queue.title,
            'new': queue_tickets.filter(status=0).count(),
            'open': queue_tickets.filter(status__in=[1, 2]).count(),
            'resolved': queue_tickets.filter(status=3).count(),
            'closed': queue_tickets.filter(status=4).count(),
            'time_spent': format_time_spent(time_spent(queue_tickets)),
            'dedicated_time': format_time_spent(queue.dedicated_time)
        }
        dash_tickets.append(dash_ticket)

    return render(request, 'helpdesk/report_index.html', {
        'number_tickets': number_tickets,
        'saved_query': saved_query,
        'basic_ticket_stats': basic_ticket_stats,
        'dash_tickets': dash_tickets,
    })


def run_report(request, report):
    tickets = get_user_tickets(request.user)
    if tickets.count() == 0 or report not in (
            'queuemonth', 'usermonth', 'queuestatus', 'queuepriority', 'userstatus',
            'userpriority', 'userqueue', 'daysuntilticketclosedbymonth'):
        return HttpResponseRedirect(reverse("helpdesk:report_index"))

    report_queryset = tickets.select_related().filter(
        queue__in=HelpdeskUser(request.user).get_queues()
    )

    try:
        saved_query, query_params = load_saved_query(request)
    except QueryLoadError:
        return HttpResponseRedirect(reverse('helpdesk:report_index'))

    if request.GET.get('saved_query', None):
        Query(report_queryset, query_to_base64(query_params))

    from collections import defaultdict
    summarytable = defaultdict(int)
    # a second table for more complex queries
    summarytable2 = defaultdict(int)

    first_ticket = tickets.order_by('created')[0]
    first_month = first_ticket.created.month
    first_year = first_ticket.created.year

    last_ticket = tickets.order_by('-created')[0]
    last_month = last_ticket.created.month
    last_year = last_ticket.created.year

    periods = []
    year, month = first_year, first_month
    working = True
    periods.append("%s-%02d" % (year, month))

    while working:
        month += 1
        if month > 12:
            year += 1
            month = 1
        if (year > last_year) or (month > last_month and year >= last_year):
            working = False
        periods.append("%s-%02d" % (year, month))

    if report == 'userpriority':
        title = _('User by Priority')
        col1heading = _('User')
        possible_options = [t[1].title() for t in Ticket.PRIORITY_CHOICES]
        charttype = 'bar'

    elif report == 'userqueue':
        title = _('User by Queue')
        col1heading = _('User')
        queue_options = HelpdeskUser(request.user).get_queues()
        possible_options = [q.title for q in queue_options]
        charttype = 'bar'

    elif report == 'userstatus':
        title = _('User by Status')
        col1heading = _('User')
        possible_options = [s[1].title() for s in Ticket.STATUS_CHOICES]
        charttype = 'bar'

    elif report == 'usermonth':
        title = _('User by Month')
        col1heading = _('User')
        possible_options = periods
        charttype = 'date'

    elif report == 'queuepriority':
        title = _('Queue by Priority')
        col1heading = _('Queue')
        possible_options = [t[1].title() for t in Ticket.PRIORITY_CHOICES]
        charttype = 'bar'

    elif report == 'queuestatus':
        title = _('Queue by Status')
        col1heading = _('Queue')
        possible_options = [s[1].title() for s in Ticket.STATUS_CHOICES]
        charttype = 'bar'

    elif report == 'queuemonth':
        title = _('Queue by Month')
        col1heading = _('Queue')
        possible_options = periods
        charttype = 'date'

    elif report == 'daysuntilticketclosedbymonth':
        title = _('Days until ticket closed by Month')
        col1heading = _('Queue')
        possible_options = periods
        charttype = 'date'

    metric3 = False
    for ticket in report_queryset:
        if report == 'userpriority':
            metric1 = u'%s' % ticket.get_assigned_to
            metric2 = u'%s' % ticket.get_priority_display()

        elif report == 'userqueue':
            metric1 = u'%s' % ticket.get_assigned_to
            metric2 = u'%s' % ticket.queue.title

        elif report == 'userstatus':
            metric1 = u'%s' % ticket.get_assigned_to
            metric2 = u'%s' % ticket.get_status_display()

        elif report == 'usermonth':
            metric1 = u'%s' % ticket.get_assigned_to
            metric2 = u'%s-%s' % (ticket.created.year, ticket.created.month)

        elif report == 'queuepriority':
            metric1 = u'%s' % ticket.queue.title
            metric2 = u'%s' % ticket.get_priority_display()

        elif report == 'queuestatus':
            metric1 = u'%s' % ticket.queue.title
            metric2 = u'%s' % ticket.get_status_display()

        elif report == 'queuemonth':
            metric1 = u'%s' % ticket.queue.title
            metric2 = u'%s-%02d' % (ticket.created.year, ticket.created.month)

        elif report == 'daysuntilticketclosedbymonth':
            metric1 = u'%s' % ticket.queue.title
            metric2 = u'%s-%02d' % (ticket.created.year, ticket.created.month)
            metric3 = ticket.modified - ticket.created
            metric3 = metric3.days

        summarytable[metric1, metric2] += 1
        if metric3:
            if report == 'daysuntilticketclosedbymonth':
                summarytable2[metric1, metric2] += metric3

    table = []

    if report == 'daysuntilticketclosedbymonth':
        for key in summarytable2.keys():
            summarytable[key] = summarytable2[key] / summarytable[key]

    header1 = sorted(set(list(i for i, _ in summarytable.keys())))

    column_headings = [col1heading] + possible_options

    # Prepare a dict to store totals for each possible option
    totals = {}
    # Pivot the data so that 'header1' fields are always first column
    # in the row, and 'possible_options' are always the 2nd - nth columns.
    for item in header1:
        data = []
        for hdr in possible_options:
            if hdr not in totals.keys():
                totals[hdr] = summarytable[item, hdr]
            else:
                totals[hdr] += summarytable[item, hdr]
            data.append(summarytable[item, hdr])
        table.append([item] + data)

    # Zip data and headers together in one list for Morris.js charts
    # will get a list like [(Header1, Data1), (Header2, Data2)...]
    seriesnum = 0
    morrisjs_data = []
    for label in column_headings[1:]:
        seriesnum += 1
        datadict = {"x": label}
        for n in range(0, len(table)):
            datadict[n] = table[n][seriesnum]
        morrisjs_data.append(datadict)

    series_names = []
    for series in table:
        series_names.append(series[0])

    # Add total row to table
    total_data = ['Total']
    for hdr in possible_options:
        total_data.append(str(totals[hdr]))

    return render(request, 'helpdesk/report_output.html', {
        'title': title,
        'charttype': charttype,
        'data': table,
        'total_data': total_data,
        'headings': column_headings,
        'series_names': series_names,
        'morrisjs_data': morrisjs_data,
        'from_saved_query': saved_query is not None,
        'saved_query': saved_query,
    })
