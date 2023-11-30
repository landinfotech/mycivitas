from django.shortcuts import render, redirect
from . import CommunitySecureView

class VersionView(CommunitySecureView):
    """
    Short description of release
    """
    
    def get(self, request, *args, **kwargs):
        context = {}
        return render(request, 'version.html', context)