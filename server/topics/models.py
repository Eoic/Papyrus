from django.db import models


class Topic(models.Model):
    title = models.CharField(max_length=25)
    description = models.TextField(blank=True, null=True)
    color = models.CharField(max_length=7, default="#000000")
    owner = models.ForeignKey('auth.User', related_name='topics', on_delete=models.CASCADE)

    def __str__(self):
        return self.title