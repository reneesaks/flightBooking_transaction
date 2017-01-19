delimiter $$
create procedure broneeri 
  (
    in klient int,  
    in lend int, 
    out aegk int, 
    out lendk int, 
    out klientk int, 
    out kohadk int, 
    out keeldk int, 
    out olemask int, 
    out viga varchar(100)
  )

  begin

  set aegk=0;
  set lendk=0;
  set klientk=0;
  set kohadk=0;
  set keeldk=0;
	set olemask=0;
  select * from lend;
  select * from klient;
  select * from broneering;
	START TRANSACTION;

  # kas aeg on möödas, 4 tundi
	if (select timediff(
      (select kuupaev from lend where lennu_id=lend)
        , now())) > '04:00:00' then
         begin
       	  set aegk=1;
     	end; 
         else
          select'aeg on möödas';
        end if;

 # kas selline lend on olemas
   if exists (select lennu_id from lend where lennu_id=lend) then
    begin
        set lendk=1;
     end;
      else 
        select'sellist lendu ei eksisteeri';
     end if;

 # kas selline klient on olemas
   if exists (select klient_id from klient where klient_id=klient) then
    begin
        set klientk=1;
     end;
      else 
        select 'sellist klienti ei ole';
     end if;

 # kas vabu kohti on
   if (select bron_kohad from lend where lennu_id=lend) <=
   (select istekohad from lend where lennu_id=lend) - 1 then
    begin
        set kohadk=1;
     end;
      else 
        select 'vabu kohti ei ole';
     end if;

 # kas lennukeeld on peal
  if (select lennukeeld from klient where klient_id=klient) = 
  (select('ei'))
    then
    begin
        set keeldk=1;
     end;
      else 
        select 'teil ei ole lubatud lennata';
     end if;

 # kas on juba see lend sama inimese poolt broneeritud
   if (select ln_id from broneering where kl_id=klient && ln_id=lend) = lend then
    begin
        select 'olete juba broneerinud';
     end;
      else 
        set olemask=1;
     end if;

 # kui kõik kriteeriumid on täidetud
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
  select 'broneering õnnestus';
  else 
  select 'tekkis viga';
  ROLLBACK;
  end if;
end$$
delimiter ;