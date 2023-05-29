from django.http import Http404
from django.contrib.auth.decorators import login_required
from django.shortcuts import get_object_or_404
from django.shortcuts import render, redirect
from django.utils.decorators import method_decorator

from . import CommunitySecureView
from civitas.models.community import Community
from civitas.models.view.reporter_data import ReporterData

class DashboardListView(CommunitySecureView):
    """
    List Communities Linked to User
    """
    
    def get(self, request, *args, **kwargs):
        """ Dashboard view of an community """
        community = request.user.communities.order_by("name")
        if community.count() == 1:
            return redirect('community-dashboard-detailed', pk=community[0].id)
        context = {
            "communities" : community
        }
        return render(request, 'dashboard/list.html', context)
    
class DashboardDetailedView(CommunitySecureView):
    """
    Display dashboard of selected community
    """
    def get(self, request, pk, *args, **kwargs):
        """ Dashboard view of an community """
        try:
            community = request.user.communities.get(pk=pk)
            context = {
                "community" : community,
                "reporter_data": ReporterData.by_community(community),
                "dashboard" : ReporterData.dashboard(community),
            }
            return render(request, 'dashboard/dashboard.html', context)
        except Community.DoesNotExist:
            raise Http404