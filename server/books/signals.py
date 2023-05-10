from django.db import models
from books.models import Book
from main.utils import FileUtils
from django.dispatch import receiver


@receiver(models.signals.post_delete, sender=Book)
def delete_file(sender, instance, *args, **kwargs):
    if instance.file:
        FileUtils.delete_file(instance.file.path)

    if instance.cover:
        FileUtils.delete_file(instance.cover.path)
