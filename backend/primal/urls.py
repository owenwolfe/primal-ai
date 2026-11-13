from django.urls import path

from primal import views

urlpatterns = [
    path("health", views.health),
    path("api/v1/evaluations", views.evaluate_label),
]
handler404 = views.not_found
handler500 = views.server_error
