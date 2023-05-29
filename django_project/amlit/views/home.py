from django.contrib.auth.views import LoginView


class HomeView(LoginView):
    template_name = 'pages/home.html'

    def get_context_data(self, **kwargs):
        context = super().get_context_data(**kwargs)
        return context
