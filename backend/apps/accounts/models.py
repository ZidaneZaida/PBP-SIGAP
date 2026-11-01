import uuid

from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models
from django.utils import timezone


class UserManager(BaseUserManager):
    use_in_migrations = True

    def _create_user(self, email, password, **extra_fields):
        if not email:
            raise ValueError("Email wajib diisi.")
        email = self.normalize_email(email).lower()
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_user(self, email, password=None, **extra_fields):
        extra_fields.setdefault("role", User.Role.CITIZEN)
        extra_fields.setdefault("is_staff", False)
        extra_fields.setdefault("is_superuser", False)
        return self._create_user(email, password, **extra_fields)

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault("role", User.Role.SUPERADMIN)
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        return self._create_user(email, password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    class Role(models.TextChoices):
        CITIZEN = "citizen", "Warga"
        OFFICER = "officer", "Petugas BPBD"
        EDITOR = "editor", "Editor Berita"
        SUPERADMIN = "superadmin", "Superadmin"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True)
    full_name = models.CharField(max_length=150)
    role = models.CharField(max_length=20, choices=Role.choices, default=Role.CITIZEN)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    date_joined = models.DateTimeField(default=timezone.now)

    objects = UserManager()

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["full_name"]

    class Meta:
        db_table = "accounts_user"
        ordering = ["-date_joined"]
        verbose_name = "Pengguna"
        verbose_name_plural = "Pengguna"
        indexes = [models.Index(fields=["role"], name="idx_users_role")]

    def __str__(self):
        return f"{self.full_name} <{self.email}>"

    @property
    def is_officer(self):
        return self.role in {self.Role.OFFICER, self.Role.SUPERADMIN}

    @property
    def is_editor(self):
        return self.role in {self.Role.EDITOR, self.Role.SUPERADMIN}

class UserProfile(models.Model):
    """Data profil opsional + preferensi notifikasi (digabung)."""

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(
        User, on_delete=models.CASCADE, related_name="profile"
    )
    phone = models.CharField(max_length=20, blank=True)
    photo_url = models.TextField(blank=True)
    primary_area = models.CharField(max_length=100, blank=True, default="Kota Padang")
    address_note = models.TextField(blank=True)
    alert_enabled = models.BooleanField(default=True)
    news_enabled = models.BooleanField(default=True)
    family_enabled = models.BooleanField(default=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "user_profiles"
        verbose_name = "Profil"
        verbose_name_plural = "Profil"

    def __str__(self):
        return f"Profil {self.user_id}"


class DeviceToken(models.Model):
    """Token FCM. Satu device = satu token (unique)."""

    class Platform(models.TextChoices):
        ANDROID = "android", "Android"
        WEB = "web", "Web"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        User, on_delete=models.CASCADE, related_name="device_tokens"
    )
    fcm_token = models.TextField(unique=True)
    platform = models.CharField(
        max_length=10, choices=Platform.choices, default=Platform.ANDROID
    )
    created_at = models.DateTimeField(auto_now_add=True)
    last_used_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = "device_tokens"
        ordering = ["-created_at"]

    def __str__(self):
        return f"{self.platform} {self.fcm_token[:12]}"
