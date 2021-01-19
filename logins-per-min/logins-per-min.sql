-- Logins per/minute
export to logins-per-min.del of del

select
    to_char(login_date, 'YYYY-MM-DD') as login_date,
    hour(login_date)                  as hour,
    minute(login_date)                as minute,
    count(*)                          as login_count

from
    GMS4.sms_user_login
where
    date(login_date) between 
         (current date - 1 day) and  current date 
group by
   to_char(login_date, 'YYYY-MM-DD'),
   hour(login_date),
   minute(login_date)

order by
    login_date

with ur;

export to logins-per-min-archive.del of del

select
    to_char(login_date, 'YYYY-MM-DD') as login_date,
    hour(login_date)                  as hour,
    minute(login_date)                as minute,
    count(*)                          as login_count

from
    GMS4.sms_user_login_archive
where
    date(login_date) between 
         (current date - 1 day) and  current date 
group by
   to_char(login_date, 'YYYY-MM-DD'),
   hour(login_date),
   minute(login_date)

order by
    login_date

with ur;
