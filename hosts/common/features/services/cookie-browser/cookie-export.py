import asyncio
import io
import os
from typing import cast

from aiohttp import web
from yt_dlp.cookies import YoutubeDLCookieJar, extract_cookies_from_browser

PROFILE_PATH: str = os.environ["PROFILE_PATH"]

PORT: int = int(os.environ["PORT"])


def read_cookies() -> YoutubeDLCookieJar:
    return extract_cookies_from_browser("chrome", profile=PROFILE_PATH)


async def serve_cookies(_request: web.Request) -> web.Response:
    cookies_file: io.StringIO = io.StringIO()

    (await asyncio.to_thread(read_cookies)).save(cast(str, cookies_file))  # yt-dlp writes to a file object too, though it annotates only a path

    return web.Response(text=cookies_file.getvalue())


async def serve_health(_request: web.Request) -> web.Response:
    cookies: YoutubeDLCookieJar = await asyncio.to_thread(read_cookies)

    return web.Response(text=f"{len(cookies)} cookies")


def main() -> None:
    app: web.Application = web.Application()

    app.router.add_get("/", serve_cookies)
    app.router.add_get("/health", serve_health)

    web.run_app(app, host="127.0.0.1", port=PORT)


if __name__ == "__main__":
    main()
