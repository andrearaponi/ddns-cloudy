# DDNS Self-Hosted with CloudFlare

![Version](https://img.shields.io/badge/version-1.0.0-green.svg)


A simple script to update your DNS records on CloudFlare. This script leverages CloudFlare's API to dynamically update DNS records.

## Features:

- Check if another instance of the script is running
- Self-installation and configuration initialization
- Periodic updates using crontab
- Logging of updates
- Simple uninstallation

## Installation:

1. Clone the repository:
```bash
git clone https://github.com/andrearaponi/ddns-cloudy
```

2. Navigate to the repository:
```bash
cd ddns-cloudy
```

3. Ensure the script is executable:
```bash
chmod +x ddns-cloudy.sh
```

4. Run the script with sudo privileges to initialize configuration:
```bash
sudo ./ddns-cloudy.sh
```


5. Follow the on-screen instructions to set up your CloudFlare configuration.

## Usage:

Once installed, the script will automatically run at the specified interval using crontab. 

However, you can manually trigger an update by running:

```bash
/usr/local/bin/ddns-cloudy.sh run
```

## Uninstallation:

Run the script with sudo privileges and choose the "Uninstall" option:
```bash
sudo ./ddns-cloudy.sh
```


## Requirements:

- `curl`: Used for API requests
- `dig`: Used to fetch public IP address

## Configuration:

Configuration is stored in `~/.cloudflare_update_config`. This file contains sensitive information (API Key) and should be kept secure.

## Logs:

Logs can be found in `/var/log/cloudflare_update.log`. They provide a history of DNS updates.

## Buy me a coffee

Whether you use this project, have learned something from it, or just like it, please consider supporting it by buying me a coffee, so I can dedicate more time on open-source projects like this 

<a href="https://www.buymeacoffee.com/andrearapoA" target="_blank"><img src="https://www.buymeacoffee.com/assets/img/custom_images/orange_img.png" alt="Buy Me A Coffee" style="height: auto !important;width: auto !important;" ></a>

## License
>You can check out the full license [here](https://github.com/andrearaponi/ddns-cloudy/blob/main/LICENSE)

This project is licensed under the terms of the **MIT** license.

---
---

**Note**: It's essential to ensure that users are aware of any sensitive information the script handles, especially when dealing with API keys. Always advise users to be cautious and not to share the configuration file with anyone else.
