import logging
import os
import sys
import threading
from datetime import datetime
from pathlib import Path
from time import sleep

import schedule

from .utils_filesystem import check_freespace_low


# datefmt = '%Y%m%d %I:%M:%S%p'
# formatter = '%(asctime)s %(levelname)s %(funcName)s: %(message)s'
# logging.basicConfig(
#     format=formatter,
#     datefmt=datefmt,
#     level=logging.DEBUG,
# )
log = logging.getLogger('orion.jobs')
# log = logging.getLogger(__name__)
# log.setLevel(logging.DEBUG)


# -- Constants -- #
APP_BASE = Path(__file__).resolve(strict=True).parent




def job_check_freespace():
    """" A job to check disk free space across a list of root mountpoints. """
    sent_time = None
    delay_until = None

    path_list = [
        '/',
        '/processing',
        '/data',
        '/data2',
    ]

    log.debug(f"Checking disk free space in {len(path_list)} defined root paths")
    for root in path_list:
        if check_freespace_low(root, min_threshold=20000000):

            if not sent_time or (delay_until < datetime.now()):
                # Send a message if we haven't already, or it's past our throttling delay
                # so as to avoid excessive messages being sent.
                # messenger = BountyBot()
                # messenger.send_message(f"Server Disk Low! ({root}) Free space below threshold!")
                sent_time = datetime.now()
                delay_until = datetime.now() + datetime.timedelta(minutes=20)

    return


def job_check_ram():
    """ Job to monitor RAM usage and do something if it's too high. """

    # import psutil

    # # get a named tuple of system memory usage.
    # # 3rd tuple is % used of RAM,
    # # 5th tuple is "free" memory not used and available

    # current_ram_usage = psutil.virtual_memory()[2]

    total_memory, used_memory, free_memory = map(
        int, os.popen("free -t -m").readlines()[-1].split()[1:]
    )

    current_ram_usage = round((used_memory/total_memory) * 100, 1)

    if current_ram_usage >= 90:
        print("[!] CRITICAL: RAM utilization has exceeded 90%!")
        # messenger = BountyBot()
        # messenger.send_message(":rotating_light:  CRITICAL: RAM utilization has exceeded 90%!")

    # if current_ram_usage >= 98:
        # find python processes and kill them?

    return



def job_test_bulkimporter():
    """ Test our bulk importer as a full job. """
    pass
    # bulker = BulkImporter(
    #     'aetna',
    #     '/output_data/aetna',
    #     dryrun=False,
    #     do_journal=True,
    #     do_delete=True,
    # )
    # bulker.run()
    return






class AppScheduler():
    """ A class to operate as our schedule manager.

        - Help: https://zerowithdot.com/scheduler-in-python/
        - Another scheduler: https://github.com/sjdavalle/Task-Scheduler/blob/main/scheduler.py

    """
    def __init__(self):
        self.scheduler = schedule.Scheduler()
        self.job_registry = []
        self.stop_event = threading.Event()     # Future, can use this across class to stop running scheduler
        #self.task_completed_event = threading.Event()
        self.load_jobs()
        log.debug("AppScheduler has been initialized and jobs loaded")

    def load_jobs(self):
        """ Load our static list of jobs for this application. """
        log.debug("Loading all jobs defined in self.load_jobs()")

        log.info("Loading Job: Check disk freespace")
        self.scheduler.every().hour.do(job_check_freespace).tag('hourly-tasks', 'system')

        log.info("Loading Job: Check RAM utilization")
        self.scheduler.every().minute.do(job_check_ram).tag('system')
        #log.info("Loading Job: dolthub repo check")
        #self.scheduler.every().day.at('08:00').do(job_check_dolthub_repo).tag('daily-tasks')

        #self.scheduler.every(10).minutes.do(job_test_bulkimporter)
        return

    def get_jobs(self):
        return self.scheduler.get_jobs()

    def add_job(self, task, interval_type='minutes', interval_int=30):
        """ Add a job by specifying all the params.

        """
        if interval_int == 0:
            interval_int = None
        if interval_type == 'minutes':
            self.scheduler.every(interval_int).minutes.do(task)
        elif interval_type == 'hours':
            self.scheduler.every(interval_int).hours.do(task)
        log.debug("Job added to scheduler")
        # NOTE: Job() syntax:
        #   Job(interval=10, unit=minutes, do=task, args=(), kwargs={})
        return


    def run_continuously(self, interval=30):
        """ Continuously run schedule in thread, executing pending jobs at each elapsed interval.

            - https://schedule.readthedocs.io/en/stable/background-execution.html

            Usage:
                schedule.every().second.do(some_job)
                stop_running = run_continuously()
                # do other stuff
                # Stop the background thread when ready to quit
                stop_running.set()

        """
        #cease_continuous_run = threading.Event()

        class ScheduleThread(threading.Thread):
            @classmethod
            def run(cls):
                #while not cease_continuous_run.is_set():
                log.debug("Beginning endless scheduler loop inside thread now")
                while not self.stop_event.is_set():
                    self.scheduler.run_pending()
                    sleep(interval)

        continuous_thread = ScheduleThread()
        continuous_thread.start()
        #return cease_continuous_run
        return

    def stop_all(self):
        # TODO: Implement shutdown within the class itself?
        log.debug("Shutting down scheduler")
        self.stop_event.set()
        return
# -- End of Class --



def main():
    # Run our custom app scheduler until we CTRL+C to quit
    scheduler1 = AppScheduler()
    #scheduler1.load_jobs()
    scheduler1.run_continuously()


    while True:
        try:
            sleep(10)
        except (KeyboardInterrupt, SystemExit):
            scheduler1.stop_all()
            sys.exit(0)
    return


if __name__ == '__main__':
    main()
    sys.exit()


    ### Simple way of doing it
    scheduler1 = schedule.Scheduler()

    # Every x minutes, run our disk free checker
    log.info("[*] Launching job for periodic disk free checker...")
    #schedule.every(30).minutes.do(job_check_freespace)
    scheduler1.every().hour.do(job_check_freespace).tag('hourly-tasks', 'maintenance')


    # TODO: I could do a once daily job that submits my commit PR...
    #scheduler1.every().day.at('19:00').do(job_push_branch)

    scheduler1.every().day.at('08:00').do(job_check_dolthub_repo).tag('daily-tasks')

    while True:
        scheduler1.run_pending()
        #scheduler2.run_pending()       # If i needed multiple schedulers
        sleep(60)
