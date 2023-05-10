from os import path
from django.db import models
from django.utils.timezone import now

def get_book_upload_path(instance, filename):
    return path.join('books', 'user_' + str(instance.owner.id), 'documents', filename)

def get_book_cover_upload_path(instance, filename):
    return path.join('books', 'user_' + str(instance.owner.id), 'covers', filename)

class Book(models.Model):
    title = models.CharField(max_length=255)
    author = models.CharField(max_length=512, null=True, blank=True)
    isbn_10 = models.CharField(max_length=10, null=True, blank=True)
    isbn_13 = models.CharField(max_length=13, null=True, blank=True)
    publisher = models.CharField(max_length=100, null=True, blank=True)
    language = models.CharField(max_length=50, null=True, blank=True)
    genre = models.CharField(max_length=100, null=True, blank=True)
    description = models.TextField(null=True, blank=True)
    cover = models.ImageField(upload_to=get_book_cover_upload_path, null=True, blank=True)
    pages = models.IntegerField(null=True, blank=True)
    format = models.CharField(max_length=50, null=True, blank=True)
    owner = models.ForeignKey('auth.User', related_name='books', on_delete=models.CASCADE)
    file = models.FileField(upload_to=get_book_upload_path, null=True, blank=True)
    published_at = models.DateField(null=True, blank=True)
    created_at = models.DateTimeField(null=True, blank=True, editable=False)
    updated_at = models.DateTimeField(null=True, blank=True, editable=False)
    shelf = models.ForeignKey(to='shelves.Shelf', on_delete=models.SET_NULL, blank=True, null=True)
    topics = models.ManyToManyField(to='topics.Topic', blank=True)

    class Meta:
        ordering = ['created_at']

    def save(self, *args, **kwargs) -> None:
        if not self.id:
            self.created_at = now()

        self.updated_at = now()
        return super().save(*args, **kwargs)
