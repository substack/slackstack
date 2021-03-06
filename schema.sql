create table posts (
    id char(6) unique primary key not null,
    title text,
    timestamp datetime,
    body text,
    description text
);

create table categories (
    id integer primary key,
    title text
);

create table category_map (
    category integer,
    post integer
);

create table media (
    id integer primary key,
    mime text,
    name text,
    path text
);

create table media_map (
    post_id integer,
    media_id integer
);

create table openid_sessions (
    id text unique,
    addr text,
    session text
);

create table sessions (
    id char(32) unique primary key not null,
    addr text,
    identity text
);

create table access (
    identity text,
    level integer
);

-- create root user:
insert into access
    (identity, level)
    values ('http://substack.myopenid.com', 0)
;
