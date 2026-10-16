import os, re, shutil

PROJECT = os.environ.get('REORG_PROJECT') or os.path.expanduser('~/mnt/PodCast')
ROOT = os.path.join(PROJECT, 'Podcast')
TRASH = os.path.join(PROJECT, '_to_delete')

def P(p):
    return os.path.join(ROOT, p)

cache, removed, pending = {}, {}, []

def lines(src):
    if src not in cache:
        cache[src] = open(P(src)).read().split('\n')
    return cache[src]

def imports_of(src):
    return [l[len('import '):].strip() for l in lines(src) if l.startswith('import ')]

def take(src, a, b, drop_from=None):
    """Removes lines drop_from..b from src (1-based, inclusive) and returns a..b."""
    L = lines(src)
    removed.setdefault(src, set()).update(range(drop_from or a, b + 1))
    return '\n'.join(L[a - 1:b])

def drop(src, a, b):
    removed.setdefault(src, set()).update(range(a, b + 1))

def header(name):
    return f"//\n//  {name}\n//  Podcast\n//\n"

def new_file(dest, imports, *chunks, trash=False):
    pending.append((dest, imports, chunks, trash))

def write_new():
    for dest, imports, chunks, trash in pending:
        path = os.path.join(TRASH, dest) if trash else P(dest)
        os.makedirs(os.path.dirname(path), exist_ok=True)
        assert not os.path.exists(path), dest
        body = '\n\n'.join(c.strip('\n') for c in chunks)
        seen, imps = set(), []
        for i in imports:
            if i not in seen:
                seen.add(i); imps.append(i)
        text = header(os.path.basename(dest)) + '\n'
        if imps:
            text += '\n'.join(f'import {i}' for i in imps) + '\n\n'
        open(path, 'w').write(text + body + '\n')
        print('new ', ('_to_delete/' if trash else '') + dest)

def rewrite_sources():
    for src, rem in removed.items():
        keep = [l for i, l in enumerate(lines(src), 1) if i not in rem]
        text = re.sub(r'\n{3,}', '\n\n', '\n'.join(keep)).rstrip() + '\n'
        open(P(src), 'w').write(text)
        print('edit', src)

def append(dest, chunk):
    with open(P(dest), 'a') as f:
        f.write('\n' + chunk.strip('\n') + '\n')
    print('add ', dest)

def mv(src, dest, trash=False):
    target = os.path.join(TRASH, dest) if trash else P(dest)
    os.makedirs(os.path.dirname(target), exist_ok=True)
    assert not os.path.exists(target), dest
    shutil.move(P(src), target)
    # Keep the header comment in sync with the file name.
    text = open(target).read()
    text = re.sub(r'^//  .*\.swift$', f'//  {os.path.basename(dest)}', text, count=1, flags=re.M)
    open(target, 'w').write(text)
    print('move', src, '->', ('_to_delete/' if trash else '') + dest)

def replace(path, old, new, count=None):
    full = P(path)
    text = open(full).read()
    n = text.count(old)
    assert n >= 1 and (count is None or n == count), (path, old, n)
    open(full, 'w').write(text.replace(old, new))

# ---------------------------------------------------------------- extraction

# Library: one file mixed six types.
src = 'Presentation/Library/LibraryMenuItem.swift'
imp = imports_of(src)
library_view = take(src, 21, 117, drop_from=19)
library_preview = take(src, 214, 220, drop_from=212)
new_file('Presentation/Library/LibraryView.swift', imp, library_view, '// MARK: - Preview', library_preview)
new_file('Presentation/Library/Components/LibraryMenuRow.swift', imp, take(src, 120, 144, drop_from=118))
new_file('Presentation/Common/Components/RecentUpdateCard.swift', imp, take(src, 147, 204, drop_from=145))
drop(src, 205, 211)  # private Color with an RGB value -> AppColor.screenBackground
new_file('Presentation/Library/LibraryActions.swift', imp, take(src, 230, 246))
drop(src, 10, 10)    # "// MARK: - Models"

# Home
src = 'Presentation/Home/HomeView.swift'
imp = imports_of(src)
new_file('Presentation/Home/Components/ContinueListeningCard.swift', imp, take(src, 170, 243, drop_from=168))
new_file('Presentation/Home/Components/PodcastTile.swift', imp,
         take(src, 246, 269, drop_from=244).replace('private struct PodcastTile', 'struct PodcastTile', 1))
drop(src, 270, 277)  # private Color with RGB values

# Bottom bar
src = 'Presentation/Player/Mini/BottomBar.swift'
imp = imports_of(src)
new_file('Presentation/Player/Mini/MiniPlayerCapsule.swift', imp,
         take(src, 179, 258, drop_from=177).replace('private struct MiniPlayerCapsule', 'struct MiniPlayerCapsule', 1))
new_file('Presentation/Common/Modifiers/View+GlassCapsule.swift', imp,
         take(src, 261, 267, drop_from=259).replace('private extension View', 'extension View', 1))
drop(src, 268, 273)  # private Color with RGB values

# Navigation
src = 'App/AppNavigator.swift'
new_file('App/Navigation/AppTab.swift', ['Foundation'], take(src, 9, 33))
src = 'App/MainNavigation.swift'
new_file('App/Navigation/MainContainerController.swift', ['UIKit'], take(src, 32, 125))

# Episodes
src = 'Presentation/Episodes/EpisodeHeaderView.swift'
imp = imports_of(src)
new_file('Presentation/Episodes/Components/WaveformIcon.swift', imp, take(src, 169, 199))
new_file('Presentation/Episodes/Components/DynamicPodcastHeroBackground.swift', imp, take(src, 200, 220))

src = 'Presentation/Episodes/HeaderState.swift'
actions = take(src, 22, 49)
env = take(src, 53, 63)
drop(src, 50, 52)
new_file('Presentation/Episodes/EpisodeHeaderActions.swift', ['SwiftUI'], actions, '// MARK: - Environment', env)

# Download button is shared by Bookmarks and Downloads.
src = 'Presentation/Bookmarks/BookMarkView.swift'
new_file('Presentation/Common/Components/DownloadButton.swift', imports_of(src), take(src, 86, 195))

# Search results cell: the Podcast mock belongs to Podcast.
src = 'Presentation/Search/Results/PodcastCell.swift'
podcast_mock = take(src, 85, 97)

# Genres cell: AppColor and Color.uiColor lived here.
src = 'Presentation/Search/Genres/GenrePodcastCell.swift'
drop(src, 9, 60)  # AppColor -> Core/DesignSystem/AppColor.swift (rewritten)
new_file('Core/Extensions/Color+UIColor.swift', ['SwiftUI', 'UIKit'], take(src, 61, 65))
genre_mock = take(src, 96, 103)

# Data / Domain
src = 'Data/Remote/PodcastRemoteDataService.swift'
imp = imports_of(src)
new_file('Data/Remote/PodcastEndpoint.swift', ['Foundation', 'Alamofire'], take(src, 19, 53))
new_file('Data/Remote/PodcastRemoteDataSource.swift', ['Foundation'], take(src, 54, 74))
new_file('Core/Concurrency/WithTimeout.swift', ['Foundation'], take(src, 230, 260))
new_file('Unused/UnusedNetworkingTypes.swift', ['Foundation', 'Alamofire'],
         '// Nothing in the app referenced these types.',
         take(src, 12, 18), take(src, 210, 229), trash=True)

src = 'Data/Local/LocalTranscriptionService.swift'
new_file('Data/Local/TranscriptionError.swift', ['Foundation'], take(src, 13, 28))
new_file('Domain/Entities/LocalTranscriptSegment.swift', ['Foundation'], take(src, 29, 36))
new_file('Data/Remote/AudioDownloader.swift', ['Foundation'], take(src, 164, 179, drop_from=161))

src = 'Data/Local/DownloadManager.swift'
new_file('Domain/Entities/DownloadState.swift', ['Foundation'], take(src, 11, 28))

src = 'Data/Local/RecentlyPlayedManager.swift'
new_file('Domain/Entities/RecentlyPlayed.swift', ['Foundation'], take(src, 9, 18))

src = 'Domain/Entities/Podcast.swift'
new_file('Data/Remote/DTO/SearchResults.swift', ['Foundation'], take(src, 10, 14))

src = 'Domain/Entities/GenreResponse.swift'
new_file('Domain/Entities/Genre.swift', ['Foundation'], take(src, 14, 17), genre_mock)

src = 'Core/Player/AVPlayerDataSource.swift'
new_file('Core/Player/PlayerDataSource.swift', imports_of(src), take(src, 10, 25))

src = 'Core/ImageLoading/UIImage+AverageBrightness.swift'
new_file('Core/Extensions/UIView+CornerRadius.swift', ['UIKit'], take(src, 44, 50))

src = 'Presentation/Player/PlayerDetailView.swift'
new_file('Presentation/Player/PlayerMode.swift', ['Foundation'], take(src, 8, 12))

# ---------------------------------------------------------------- write

write_new()
rewrite_sources()
append('Domain/Entities/Podcast.swift', podcast_mock)

# ---------------------------------------------------------------- renames

mv('Presentation/Library/LibraryMenuItem.swift', 'Presentation/Library/Models/LibraryMenuItem.swift')
mv('Presentation/Player/Mini/BottomBar.swift', 'App/Navigation/BottomBar.swift')
mv('App/AppNavigator.swift', 'App/Navigation/AppNavigator.swift')
mv('App/MainNavigation.swift', 'App/Navigation/MainNavigationRepresentable.swift')
mv('App/BottomBarScrollTracker.swift', 'App/Navigation/BottomBarScrollTracker.swift')
mv('Presentation/Search/Results/PodcastCell.swift', 'Presentation/Search/Results/PodcastCellUI.swift')
mv('Domain/Entities/GenreResponse.swift', 'Data/Remote/DTO/GenreResponse.swift')
mv('Presentation/Player/PlayerDetailView.swift', 'Presentation/Player/PlayerView.swift')
mv('Presentation/Player/PlayerDetailViewModel.swift', 'Presentation/Player/AVPlayerViewModel.swift')
mv('Presentation/Episodes/HeaderState.swift', 'Presentation/Episodes/Models/HeaderState.swift')
# Not used anywhere (the bottom bar replaced them).
mv('Presentation/Player/Mini/MiniPlayerView.swift', 'Unused/MiniPlayerView.swift', trash=True)
mv('Presentation/Player/Mini/CompactHeader.swift', 'Unused/CompactHeader.swift', trash=True)

# ---------------------------------------------------------------- colors in code -> AppColor

replace('Presentation/Home/HomeView.swift', 'Color.homeBackground', 'AppColor.screenBackground')
replace('Presentation/Home/HomeView.swift', 'Color.homeAccentInk', 'AppColor.lavenderInk')
replace('Presentation/Home/Components/ContinueListeningCard.swift', 'Color.homeAccentInk', 'AppColor.lavenderInk')
replace('Presentation/Library/LibraryView.swift', 'Color.libraryBackground', 'AppColor.screenBackground')
replace('App/Navigation/BottomBar.swift', 'Color.barAccentInk', 'AppColor.lavenderInk')
replace('App/Navigation/BottomBar.swift', 'Color(white: 0.96)', 'AppColor.screenBackground')
replace('Presentation/Player/PlayerView.swift',
        'private static let paper = Color(red: 0.965, green: 0.965, blue: 0.957)',
        'private static let paper = AppColor.paper', 1)
replace('Presentation/Player/PlayerView.swift',
        'private static let ink = Color(red: 0.07, green: 0.07, blue: 0.08)',
        'private static let ink = AppColor.ink', 1)

print('done')
