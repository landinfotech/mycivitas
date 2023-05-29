import logging
from django.core.exceptions import ValidationError
from django.http import HttpResponseRedirect
from django.shortcuts import render
from django.urls import reverse
from django.utils.http import urlquote
from django.utils.translation import ugettext_lazy as _

from helpdesk.decorators import is_helpdesk_staff
from helpdesk.lib import text_is_spam
from helpdesk.views import staff as staff
from helpdesk.views.public import CreateTicketView

from amlit_helpdesk.forms.ticket import AmlitTicketForm
from amlit_helpdesk.models.feature_ticket import FeatureTicket
from amlit_helpdesk.models.recurring_ticket import RecurringTicket

logger = logging.getLogger(__name__)


class StaffCreateTicketView(staff.CreateTicketView):
    """ Customized of staff.CreateTicketView
    Need to get ticket from the form
    And save it to asset ticket
    """
    form_class = AmlitTicketForm

    def form_valid(self, form):
        # check if asset ID provided
        feature_id = self.request.POST.get('feature_id', None)
        if not feature_id:
            raise ValidationError(_('Asset ID is empty'), code='invalid')
        valid_form = super().form_valid(form)
        feature_ticket = FeatureTicket.objects.create(
            ticket=self.ticket,
            features=feature_id.split(',')
        )
        recurring_type = self.request.POST.get('recurring_type', None)
        RecurringTicket.create_recurring(feature_ticket.ticket, recurring_type)
        return valid_form


class PublicCreateTicketView(CreateTicketView):
    """ Customized of CreateTicketView
    Need to get ticket from the form
    And save it to asset ticket
    """

    def form_valid(self, form):
        request = self.request

        # check if asset ID provided
        feature_id = request.POST.get('feature_id', None)
        if not feature_id:
            raise ValidationError(_('Feature ID is empty'), code='invalid')

        if text_is_spam(form.cleaned_data['body'], request):
            # This submission is spam. Let's not save it.
            return render(request, template_name='helpdesk/public_spam.html')
        else:
            ticket = form.save(user=self.request.user if self.request.user.is_authenticated else None)
            # save it to asset ticket
            feature_ticket = FeatureTicket.objects.create(
                ticket=ticket,
                features=feature_id.split(',')
            )
            recurring_type = self.request.POST.get('recurring_type', None)
            RecurringTicket.create_recurring(feature_ticket.ticket, recurring_type)
            try:
                return HttpResponseRedirect(
                    '%s?ticket=%s&email=%s&key=%s' % (
                        reverse('helpdesk:public_view'),
                        ticket.ticket_for_url,
                        urlquote(ticket.submitter_email),
                        ticket.secret_key)
                )
            except ValueError:
                # if someone enters a non-int string for the ticket
                return HttpResponseRedirect(reverse('helpdesk:home'))


def create_ticket(request, *args, **kwargs):
    if is_helpdesk_staff(request.user):
        return StaffCreateTicketView.as_view()(request, *args, **kwargs)
    else:
        return PublicCreateTicketView.as_view()(request, *args, **kwargs)
