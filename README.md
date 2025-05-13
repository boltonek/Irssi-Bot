Simple Irssi Script ( bot ) perl - current version of Irrsi bot 1.0


---

## Features

- !op <#channel> nick - get +o/@ nick 
- !ban <#channel> nick - +b/ban nick on channel
- !voice <#channel> nick - +v/voice nick in channel
- !topic <#channel> text - set topic in channel 
- !join <#channel> - join channel
- !part <#channel> - part chanel
- !say <#channel> message - say msg in channel 
- !nick <new_nick> - change nick bot
- !uptime - Uptime your system
- !version - Version your OS
- !addadmin <ident@host>  - in private msg or channel !addadmin admin@admin.com
- !deladmin <ident@host>  - in private msg or channel !deladmin admin@admin.com
- !listadmins - list admins ident@host
- !deop <#channel> nick - remove +o/@ nick on channel
- !devoice <#channel> nick - -v/voice nick in channel
- !kick <#channel> nick - kick users in channel
- !host <ip_address> - find out the name of ipv4
- !keepnick - trying to get a nickname, checking the availability of every 30sec
- !stopkeepnick - keepnick disabled
---
## Installation

```bash
# Build the application
cd .irssi/scripts

# Clone the repository
git clone https://github.com/boltonek/Irssi-Bot.git

# Build the application
choose an available scripts Czech or English

# Created admin folder
sudo nano .irssi/bot_admins.txt
and first line exampled: admin@admin.com  save the file

# run the scripts
/script load  irssi-bot-Eng.pl

```
---

### Host Management

- in channel or private msg yours botnick try test comands !help
- if you added ident@host correctly you will control a irssi bot remotely

---
## Support

For support, please:

- Report issues on IRCnet /msg bolton
- Contact support at [admin@ircnet2.cz](mailto:admin@ircnet2.cz)



