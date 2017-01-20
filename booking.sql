-- procedure start
drop procedure broneeri;
delimiter $$
create procedure broneeri 
(
  in klient int,  
  in lend int
)

begin

declare aegk int;
declare lendk int; 
declare klientk int;
declare kohadk int; 
declare keeldk int; 
declare olemask int;

set aegk=0;
set lendk=0;
set klientk=0;
set kohadk=0;
set keeldk=0;
set olemask=0;

/* select * from lend;
select * from klient;
select * from broneering; */

START TRANSACTION;

-- kas aeg on möödas, 4 tundi
	if(select timediff(
    (select kuupaev from lend where lennu_id=lend), 
    now())) > '04:00:00' then
    begin
		set aegk=1;
    end; 
    end if;

-- kas selline lend on olemas
if exists (select lennu_id from lend where lennu_id=lend) then
    begin
      set lendk=1;
    end;
    end if;

-- kas selline klient on olemas
if exists (select klient_id from klient where klient_id=klient) then
    begin
      set klientk=1;
    end;
    end if;

-- kas vabu kohti on
if(select bron_kohad from lend where lennu_id=lend) <=
    (select istekohad from lend where lennu_id=lend) - 1 then
    begin
		set kohadk=1;
    end;
    end if;

-- kas lennukeeld on peal
if(select lennukeeld from klient where klient_id=klient) = 
    (select('ei'))
    then
    begin
		set keeldk=1;
    end;
    end if;

-- kas on juba see lend sama inimese poolt broneeritud
if not exists(select ln_id from broneering where 
  kl_id=klient && ln_id=lend) = 1 then
    begin
		set olemask=1;
    end;
    end if;

-- VEATEADE: sellist lendu ega klienti pole
if aegk=0 && lendk=0 && klientk=0 && kohadk=0 && 
    (keeldk=0 || keeldk=0) && olemask=1
then
  begin
    select 'Sellist lendu ega klienti ei eksisteeri!' as VEATEADE;
  end;
  end if;

-- VEATEADE: sellist lendu pole
if aegk=0 && lendk=0 && klientk=1 && 
    kohadk=0 && keeldk=1 && olemask=1
then
  begin
    select 'Sellist lendu ei eksisteeri!' as VEATEADE;
  end;
  end if;

-- VEATEADE: sellist klienti pole
if (aegk=0 || aegk=1) && lendk=1 && klientk=0 && 
    (kohadk=0 || kohadk=1) && (keeldk=0 || keeldk=1) && olemask=1
then
  begin
    select 'Sellist klienti ei eksisteeri!' as VEATEADE;
  end;
  end if;

-- VEATEADE: klient on juba aja samal lennul broneerinud
if (aegk=1 || aegk=0) && lendk=1 && klientk=1 && 
    (kohadk=0 || kohadk=1) && keeldk=1 && olemask=0
then
  begin
    select 'Olete juba aja broneerinud sellele lennule!' as VEATEADE;
  end;
  end if;

-- VEATEADE: lennukeeld on peal
if (aegk=0 || aegk=1) && (lendk=0 || lendk=1) && klientk=1 && 
    (kohadk=0 || kohadk=1) && keeldk=0 && olemask=1
then
  begin
    select 'Teil ei ole lubatud lennata!' as VEATEADE;
  end;
  end if;

-- VEATEADE: aeg on möödas
if aegk=0 && lendk=1 && klientk=1 && 
    (kohadk=0 || kohadk=1) && keeldk=1 && (olemask=1 || olemask=0)
then
  begin
    select 'Aeg on möödas!' as VEATEADE;
  end;
  end if;

-- VEATEADE: vabu kohti pole
if aegk=1 && lendk=1 && klientk=1 && 
    kohadk=0 && keeldk=1 && olemask=1
then
  begin
    select 'Kohad on täis!' as VEATEADE;
  end;
  end if;

if aegk=1 && lendk=1 && klientk=1 && kohadk=1 && keeldk=1 && olemask=1
then
  insert into broneering values 
    ( 
      null,
      (select klient_id from klient where klient_id=klient),
      (select lennu_id from lend where lennu_id=lend),
      (select eesnimi from klient where klient_id=klient),
      (select perenimi from klient where klient_id=klient),
      (select kuupaev from lend where lennu_id=lend),
      (select algkoht from lend where lennu_id=lend),
      (select sihtkoht from lend where lennu_id=lend),
      (select bron_kohad + 1 from lend where lennu_id=lend)
    );
  update lend set bron_kohad = bron_kohad + 1 where
    lennu_id=lend;
  COMMIT;
  select 'Broneering õnnestus!' as BRONEERING;
else
  select 'Tekkis viga. Tehing katkestati!' as VEATEADE;
  ROLLBACK;
end if;
end$$
delimiter ;
-- procedure end

-- create tables
create table lend(
lennu_id int not null,
kuupaev datetime not null,
algkoht varchar(30) not null,
sihtkoht varchar(30) not null,
bron_kohad int not null,
istekohad int not null,
PRIMARY KEY(lennu_id));

create table klient(
klient_id int not null,
eesnimi varchar(30) not null,
perenimi varchar(30) not null,
riik varchar(30) not null,
linn varchar(30) not null,
tanav varchar(30) not null,
maja_nr int not null,
lennukeeld ENUM('jah', 'ei'));

create table broneering(
br_id int not null auto_increment,
kl_id int not null,
ln_id int not null,
eesnimi varchar(30) not null,
perenimi varchar(30) not null,
kuupaev datetime not null,
algkoht varchar(30) not null,
sihtkoht varchar(30) not null,
istekoht int not null,
PRIMARY KEY(br_id));

-- insert test values into table
insert into lend values('1','2017-01-14 19:30:00','Tallinn','Frankfurt','30','32');
insert into lend values('2','2017-01-17 21:45:00','Tallinn','Riia','20','25');
insert into lend values('7','2017-01-28 03:00:00','Tallinn','Kairo','99','100');

insert into klient values('5','Edgar','Savisaar','Eesti','Tallinn','Sipelga','14','jah');
insert into klient values('6', 'Siim','Kallas','Eesti','Tallinn','Sõle','1','ei');
insert into klient values('7','Aivar','Riisalu','Eesti','Paide','Vana','28','ei');
insert into klient values('8','Laine','Jänes','Eesti','Tartu','Uus','17','jah');
insert into klient values('9','Urmas','Sõõrumaa','Eesti','Tartu','Pikk','36','ei');

-- test
call broneeri(9, 5);
call broneeri(6, 1);



