# Najpierw w terminalu: uv pip install moviepy yt-dlp

from moviepy.editor import VideoFileClip
import yt_dlp

def zrob_gifa_z_tunelu(url):
    # 1. Pobierz kawałek wideo (np. od 10 do 15 sekundy)
    ydl_opts = {'format': 'bestvideo', 'outtmpl': 'tunel.mp4'}
    with yt_dlp.YoutubeDL(ydl_opts) as ydl:
        ydl.download([url])

    # 2. Wytnij fragment i zrób GIF
    clip = VideoFileClip("tunel.mp4").subclip(10, 15).resize(0.5) # mniejszy, żeby ThinkPad nie mulił
    clip.write_gif("D:\\Technoporada\\Tapety\\psychodela.gif", fps=15)
    
    print("✅ GIF gotowy! HIK!")

zrob_gifa_z_tunelu("https://www.youtube.com/watch?v=nxDq1NVnPLM")
