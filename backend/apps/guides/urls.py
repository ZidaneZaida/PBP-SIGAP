from django.urls import path

from apps.guides.views import EmergencyContactListView, GuideListView

app_name = "guides"

urlpatterns = [
    path("emergency-contacts/", EmergencyContactListView.as_view(), name="contacts"),
    path("guides/", GuideListView.as_view(), name="guides"),
]
