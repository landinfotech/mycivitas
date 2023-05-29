# coding=utf-8
"""Project level url handler."""
from django.conf.urls import url, include
from django.contrib import admin
from django.conf import settings
from django.conf.urls.static import static

admin.autodiscover()

urlpatterns = [
    url(r'^admin/', admin.site.urls),
    url(r'^auth/', include('django.contrib.auth.urls')),
    url(r'^work-order/', include('amlit_helpdesk.urls')),
    url(r'^work-order/', include('amlit_helpdesk.urls_helpdesk')),
    url(r'^', include('civitas.urls')),
    url(r'^', include('amlit.urls')),
]

if settings.DEBUG:
    urlpatterns += static(
        settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
