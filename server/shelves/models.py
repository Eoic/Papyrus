from django.db import models


class Shelf(models.Model):
    title = models.CharField(max_length=30)
    description = models.TextField(null=True, blank=True)
    owner = models.ForeignKey('auth.User', related_name='shelves', on_delete=models.CASCADE)

    def __str__(self) -> str:
        return self.title