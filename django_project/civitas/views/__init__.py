from django.utils.decorators import method_decorator
from django.contrib.auth.mixins import LoginRequiredMixin
from civitas.permissions import CommunityAccessPermission
from django.views.generic import View


class CommunitySecureView(LoginRequiredMixin, View):
    permission_classes = (CommunityAccessPermission,)

    