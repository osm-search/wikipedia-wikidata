import os

class Languages:
    def get_languages():
        if 'LANGUAGES' in os.environ:
            return os.environ['LANGUAGES'].split(',')

        with open('config/languages.txt', 'r') as file:
            languages = file.readlines()
            languages = map(lambda line: line.strip('\n'), languages)
            languages = filter(lambda line: not line.startswith('#'), languages )
            return list(languages)

        return []
