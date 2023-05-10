import os
import shutil


class FileUtils:
    @staticmethod
    def delete_file(path):
        if os.path.isfile(path):
            os.remove(path)

    @staticmethod
    def delete_directory(path):
        if os.path.isdir(path):
            shutil.rmtree(path)