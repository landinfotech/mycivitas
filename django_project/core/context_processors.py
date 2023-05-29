
import os


def project_version(request):
    """ Read project version from file"""
    DJANGO_ROOT = os.path.dirname(
        os.path.dirname(
            os.path.dirname(os.path.abspath(__file__))
        ))
    folder = os.path.join(
        DJANGO_ROOT, 'django_project', 'version')
    version = os.path.join(
        folder, 'version.txt')
    if os.path.exists(version):
        version = (open(version, 'rb').read()).decode("utf-8")
        if version:
            return {
                'version': {
                    'url': 'https://github.com/landinfotech/mycivitas/releases/tag/{}'.format(version),
                    'name': version
                }

            }
    commit = os.path.join(
        folder, 'commit.txt')
    if os.path.exists(commit):
        commit = (open(commit, 'rb').read()).decode("utf-8")
        if commit:
            return {
                'version': {
                    'url': 'https://github.com/landinfotech/mycivitas/IGRAC-GGIS/commit/{}'.format(commit),
                    'name': commit
                }
            }
    return {}
