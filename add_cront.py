import os
import subprocess


def add_cron_job_if_not_exists(cron_command, schedule):
    tmp_crontab_file = "tmp_my_crontab"
    subprocess.run(["crontab", "-l"], stdout=open(tmp_crontab_file, "w"), check=True)
    all_tasks = open(tmp_crontab_file, "r").read()
    cmd = f"{schedule} {cron_command}"
    if cmd in all_tasks:
        subprocess.run(["rm", "-f", tmp_crontab_file], check=False)
        return

    with open(tmp_crontab_file, "a") as file:
        file.write(f"{schedule} {cron_command}\n")
    subprocess.run(["crontab", tmp_crontab_file], check=False)
    subprocess.run(["rm", "-f", tmp_crontab_file], check=False)


if __name__ == "__main__":
    bash_file_name = os.path.abspath("./update_daily.sh")
    add_cron_job_if_not_exists(f"bash {bash_file_name}", "@hourly")
