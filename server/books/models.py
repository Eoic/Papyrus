from django.db import models
from django.utils.timezone import now


class Book(models.Model):
    title = models.CharField(max_length=255)
    author = models.CharField(max_length=512, null=True, blank=True)
    isbn = models.CharField(max_length=13, null=True, blank=True)
    publisher = models.CharField(max_length=100, null=True, blank=True)
    language = models.CharField(max_length=50, null=True, blank=True)
    genre = models.CharField(max_length=100, null=True, blank=True)
    description = models.TextField(null=True, blank=True)
    cover = models.ImageField(null=True, blank=True)
    pages = models.IntegerField(null=True, blank=True)
    format = models.CharField(max_length=50, null=True, blank=True)
    owner = models.ForeignKey('auth.User', related_name='books', on_delete=models.CASCADE)
    file_url = models.CharField(max_length=1000, blank=True, null=True)
    published_at = models.DateField(null=True, blank=True)
    created_at = models.DateTimeField(null=True, blank=True, editable=False)
    updated_at = models.DateTimeField(null=True, blank=True, editable=False)

    class Meta:
        ordering = ['created_at']

    def save(self, *args, **kwargs) -> None:
        if not self.id:
            self.created_at = now()

        self.updated_at = now()
        return super().save(*args, **kwargs)
