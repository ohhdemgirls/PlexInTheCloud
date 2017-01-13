# WHAT
Run Plex in the cloud. Use rclone crypt to mount and encrypt/decrypt your (unlimited) Amazon Drive storage on the fly.

These scripts will install and configure:

- Plex
    - IP:32400/web
- PlexPy
    - localhost:8181
- NZBget
    - localhost:6789
- SickRage
    - localhost:8081
- CouchPotato
    - localhost:5050
- nzbToMedia Post-Processing
- rclone + crypt


## Example Workflow
- Systemd calls on rclone to mount your directories on boot
    - ~/LOCAL is where your local files are temporarily stored before being uploaded to Amazon
    - ~/AMZe is where rclone crypt mounts your Amazon Cloud Drive locally
        - rclone crypt encrypts/decrypts data on the fly so what you _see_ locally is decrypted, but anything pushed to Amazon is encrypted first.
    - ~/ALL is a unionsfs-fuse overlay that 'combines' the contents of ~/LOCAL & ~/AMZe
- Sickrage searches for a new TV episode and tells nzbGet to download it
- nzbget downloads the show to ~/nzbget/completed/tv
- nzbToMedia renames the file and moves it ~/LOCAL/tv
- uploadTV.sh moves the file from ~/LOCAL/tv to your Amazon Web Drive
- uploadTV.sh then tells Plex to update the library
- Plex sees new content in ~/AMZe and your new files are available!

# REQUIREMENTS
## NOT-FREE
- [Amazon Cloud Drive](https://www.amazon.com/clouddrive/home) account
    - Comes with a free 3-month trial, then $70/year for unlimited storage.
- Ubuntu 16.04 with SSH access.
    - This guide uses the [Linode](https://www.linode.com/pricing) 4GB, $20/month VPS plan.
- newsgroup provider account
    - [Find something](http://www.usenetcompare.com/) under $10/month.
- newsgroup search account
    - I like [nzbGeek](https://greycoder.com/best-usenet-indexes/)

## FREE
- Free [Plex](https://www.plex.tv/) Account
- Free [OpenSubtitles.com](http://www.opensubtitles.org) account
- Local ssh key that you'll use to SSH in to your Ubuntu machine

# HOW
- SSH into your Ubuntu host as **root**
- Git clone this repo
- Copy vars.example to vars and modify as needed
- Run bash scripts in order
    - Some steps still require manual input. In such cases the scripts will pause tell you what needs to be done and will wait for feedback before continuing. 
    - (EXAMPLE: Enabling remote access for Plex requires manual steps. The script that installs Plex will pause, tell you what to do, and ask you to type "y" once you've completed the manual steps. Once you type "y" the script will continue on it's way.)

# TODO
(see issues)

# FAQ
Q: Why bash rather than Docker/Ansible/Saltstack/Chef/Puppet/your-personal-favorite-thing
A: I deal with all of that for work and I love those tools, but they do have a learning curve and I want this to be easy to approach, modify, and use.
