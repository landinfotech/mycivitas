
from django.shortcuts import render, redirect

def Error_404(request, exception):
    data = {}
    return render(request,'pages/404.html', data)