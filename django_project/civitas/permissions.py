__author__ = 'Irwan Fathurrahman <meomancer@gmail.com>'
__date__ = '16/07/21'

from rest_framework import permissions
from civitas.models.community import Community


class CommunityAccessPermission(permissions.BasePermission):
    """
    Check if community is accessible by user
    """

    def has_permission(self, request, view):
        if not request.user.is_authenticated:
            return False
        pk = view.kwargs.get('pk', None)
        try:
            request.user.communities.get(pk=pk)
            return True
        except Community.DoesNotExist:
            try:
                Community.objects.get(pk=pk)
                return False
            except Community.DoesNotExist:
                return True
