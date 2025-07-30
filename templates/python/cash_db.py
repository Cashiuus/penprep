#!/usr/bin/env python

import argparse
import logging
import os
import sqlite3
import sys
from pathlib import Path

import asyncio
import aiosqlite


log = logging.getLogger("orion.db")
log.setLevel(logging.INFO)


class MRFDB(object):
    """
        Traditional DB class object for working with MRF Database that supports Transparency In Coverage project.

    """
    def __init__(self, db_file):
        # if not os.path.exists(db_file):
        #     log.error(f"Provided database file does not exist: {db_file}")
        #     #print(f"[!] Provided database file does not exist: {db_file}")
        #     sys.exit(1)
        self.con = sqlite3.connect(db_file)
        log.debug(f"Successfully connected to database: {db_file}")
        self.cur = self.con.cursor()
        log.debug("Cursor object is now setup")

    def create_toc_table(self):
        """ This standard layout should always match what the mrf repo is doing. """ 
        log.debug("Ensuring standard TOC table structure is in place")
        
        self.cur.execute("""CREATE TABLE IF NOT EXISTS urls (id INTEGER PRIMARY KEY, url UNIQUE, size, etag, md5, filename)""")
        self.cur.execute("CREATE TABLE IF NOT EXISTS plans (id INTEGER PRIMARY KEY, name, description)")
        self.cur.execute(
            """
            CREATE TABLE IF NOT EXISTS plan_url (
                plan_id,
                url_id,
                FOREIGN KEY (url_id) REFERENCES urls(id),
                FOREIGN KEY (plan_id) REFERENCES plans(id)
            )
            """)
        self.con.commit()
        return
    
    def current_count(self, table='urls'):
        return self.cur.execute(f"SELECT COUNT(url) FROM {table}").fetchone()[0]
    
    def total_url_size(self, table='urls'):
        return self.cur.execute(f"SELECT SUM(size) FROM {table}").fetchone()[0]

    def record_exists(self, url):
        self.cur.execute('SELECT id FROM urls WHERE url = ?', (url,))
        if self.cur.fetchone() is not None:
            # It exists
            log.debug("DB check for record exists is True")
            return True
        else:
            log.debug("DB check for record exists is False")
            return False

    def insert_plan_url(self, plan_name, description, url, size, etag, res_md5, filename):
        """
        Save a record of TOC in-network resource data to database.
        """

        self.cur.execute('SELECT id FROM plans WHERE (name, description) = (?, ?)', (plan_name, description))
        if (res := self.cur.fetchone()) is None:
            self.cur.execute('INSERT INTO plans (name, description) VALUES (?, ?)', (plan_name, description))
            plan_id = self.cur.lastrowid
        else:
            plan_id = res[0]

        self.cur.execute('SELECT id FROM urls WHERE url = ?', (url,))
        if (res := self.cur.fetchone()) is None:
            # TODO: I may want to store filename here too
            try:
                self.cur.execute('INSERT INTO urls (url, size, etag, md5, filename) VALUES (?, ?, ?, ?, ?)', (url, size, etag, res_md5, filename))
            except Exception as e:
                log.error("DB does not reflect current schema for urls table!")
                self.cur.execute('INSERT INTO urls (url, size) VALUES (?, ?)', (url, size))
            url_id = self.cur.lastrowid
        else:
            url_id = res[0]

        self.cur.execute("INSERT OR IGNORE INTO plan_url (plan_id, url_id) VALUES (?, ?)", (plan_id, url_id))
        # ? They had this in the calling function, best here or there?
        self.con.commit()
        return


    def find_items(self, field, term):
        #field = 'reporting_entity_name'
        self.cur.execute(
            "SELECT url FROM urls WHERE (?) LIKE (?)", (field, term)
        )
        for item in self.cur.fetchall():
            yield item[0]

    def yield_all_urls(self, table='urls', column='url'):
        query = f"SELECT {column} FROM {table}"
        log.debug("Fetching all records to yield back to caller")
        for item in self.cur.execute(query).fetchall():
            yield item[0]
    
    def yield_all_urls_sorted(self, table='urls', column='url'):
        query = f"SELECT {column} FROM {table} ORDER BY size ASC"
        log.debug("Fetching all records to yield back to caller")
        for item in self.cur.execute(
            query
            #"SELECT (?) FROM (?) ORDER BY size ASC", (table, column)
        ).fetchall():
            yield item[0]
    
    def yield_all_urls_unique_sorted(self, table='urls', column='url'):
        """ 
        Only get unique files, doing it this way for now to maximize my data collection efficiency.
        
        """
        query = f"SELECT url, size, filename FROM {table} GROUP BY filename ORDER BY size ASC"
        log.debug("Fetching all records to yield back to caller")
        for item in self.cur.execute(
            query
            #"SELECT (?) FROM (?) ORDER BY size ASC", (table, column)
        ).fetchall():
            # As of right now, only yielding the url value by itself, maybe in future whole tuple
            yield item[0]
    
    def __enter__(self):
        # Context Managers: https://jeffknupp.com/blog/2016/03/07/python-with-context-managers/
        return self

    def __exit__(self, *args):
        """ Close or exist the DB object, as we are finished with it. """
        self.con

# -- end of class --





class MRFAsyncDB:
    """ 
        Same as the above DB class except I'm learning to async it, 
        based on WitnessMe project. 
    
    """
    def __init__(self, db_file, connection=None):
        self.db_file = db_file
        self.connection = connection
    
    async def create_db_and_schema(self):
        """ 
        This standard layout should always match what the mrf repo is doing.
        
        """ 
        log.debug("Creating TOC table structure if it doesn't already exist")
        #async with aiosqlite.connect(self.db_file) as db:
        #log.debug("Connected to db for table creation")
        await self.db.execute(
            """CREATE TABLE IF NOT EXISTS urls (id INTEGER PRIMARY KEY, url UNIQUE, size, etag, md5, filename)"""
        )

        await self.db.execute("CREATE TABLE IF NOT EXISTS plans (id INTEGER PRIMARY KEY, name, description)")
        await self.db.execute(
            """
            CREATE TABLE IF NOT EXISTS plan_url (
                plan_id,
                url_id,
                FOREIGN KEY (url_id) REFERENCES urls(id),
                FOREIGN KEY (plan_id) REFERENCES plans(id)
            )
            """
        )
        log.debug("Finished table creation steps")
        await self.db.commit()
    

    async def add_plan(self, plan_name, description):
        return await self.db.execute(
            "INSERT OR IGNORE INTO plans (name, description) VALUES (?, ?)", [plan_name, description]
        )


    async def add_url(self, url, size, etag, res_md5, filename):
        return await self.db.execute(
            "INSERT OR IGNORE INTO urls (url, size, etag, md5, filename) VALUES (?, ?, ?, ?, ?)", [url, size, etag, res_md5, filename]
        )


    async def add_plan_url(self, plan_id, url_id):
        return await self.db.execute(
            "INSERT OR IGNORE INTO plan_url (plan_id, url_id) VALUES (?, ?)", (plan_id, url_id)
        )

    async def add_plan_and_url(self, plan_name, description, url, size, etag, res_md5, filename):
        """
        Save a record of TOC in-network resource data to database.
        """
        log.debug("Processing a plan and url dataset for addition to database")
        cursor = await self.add_plan(plan_name, description)
        plan_id = cursor.lastrowid
        if plan_id == 0:
            async with self.db.execute(
                "SELECT id FROM plans WHERE name=(?) AND description=(?)", [plan_name, description]
            ) as cursor:
                row = await cursor.fetchone()
                plan_id = row[0]

        cursor = await self.add_url(url, size, etag, res_md5, filename)
        url_id = cursor.lastrowid
        if url_id == 0:
            async with self.db.execute(
                "SELECT id FROM urls WHERE url=(?)", [url,]
            ) as cursor:
                row = await cursor.fetchone()
                url_id = row[0]

        await self.add_plan_url(plan_id, url_id)
    
    
    async def current_count(self, table='urls'):
        async with self.db.execute(f"SELECT COUNT(url) FROM {table}") as cursor:
            result = await cursor.fetchone()
            return result[0]
    
    async def total_url_size(self, table='urls'):
        async with self.db.execute(f"SELECT SUM(size) FROM {table}") as cursor:
            result = await cursor.fetchone()
            return result[0]

    async def search_urls(self, search: str):
        async with self.db.execute(
            "SELECT url FROM urls WHERE url LIKE (?)",
            [f"%{search}%"]
        ) as cursor:
            for item in cursor.fetchall():
                yield item[0]

    async def get_all_urls(self, table='urls', column='url'):
        """ Return a list of all URLs. """
        log.debug("Fetching all records to yield back to caller")
        async with self.db.execute(
            "SELECT url from urls "
        ) as cursor:
            urls = await cursor.fetchall()
        for item in urls:
            yield item[0]
    
    async def get_all_urls_sorted(self, table='urls', column='url'):
        """ Return a list of all URLs, sorted. """
        # query = f"SELECT {column} FROM {table} ORDER BY size ASC"
        log.debug("Fetching all records to yield back to caller")
        async with self.db.execute(
            "SELECT url from urls ORDER BY size ASC"
        ) as cursor:
            urls = await cursor.fetchall()
        for item in urls:
            yield item[0]
    
    async def get_urls_by_offset(self, limit=-1, offset=-1):
        """ In case want to only get a certain number of results, or page through results on different systems.
        
            Use this to process db data in batches:
                get_urls_by_offset(limit=100, offset=0)
                get_urls_by_offset(limit=100, offset=100)
                get_urls_by_offset(limit=100, offset==200) etc...
        
        """
        # TODO: All these came from WitnessMe "database.py" file, so reference that
        urls = []
        async with self.db.execute(
            "SELECT url from urls LIMIT (?) OFFSET (?)", [limit, offset]
        ) as cursor:
            urls = await cursor.fetchall()
        return urls
    
    def yield_all_urls_sorted(self, table='urls', column='url'):
        """ Generator for all URLs to my workflow. """
        # TODO: Way to make this async, and/or is it helpful to do so?
        query = f"SELECT {column} FROM {table} ORDER BY size ASC"
        log.debug("Fetching all records to yield back to caller")
        for item in self.cur.execute(query).fetchall():
            yield item[0]

    async def __aenter__(self):
        if not self.connection:
            self.db = await aiosqlite.connect(f"{self.db_file}")
            log.debug(f"Connected to database file: {self.db_file}")
        else:
            self.db = self.connection
        return self
    
    async def __aexit__(self, exec_type, exc, tb):
        log.debug("Exiting MRFAsyncDB context, closing down connection to db")
        await self.db.commit()
        if not self.connection:
            await self.db.close()
# -- End of MRFAsyncDB class --














def main():
    parser = argparse.ArgumentParser("Load URLs or data from DBs")
    parser.add_argument('-f', '--input-file', dest='input_file', help='An input file')
    parser.add_argument('-q', '--query', help='query on db to perform')

    args = parser.parse_args()

    q = ''
    if args.query:
        q = args.query

    d = MRFDB(args.input_file)
    for url in d.yield_all_urls(q):
        # do stuff with the URLs, like run the flatten_mrf() against them
        # that's in script cash_get_rates.py, so let's just add this functionality
        # there.
        print(url)

    return


if __name__ == '__main__':
    main()
