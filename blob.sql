/*
htp.p can be used to output the results of a query as a file for download via a browser.
The procedure takes a varchar2 as an input parameter.
varchar2 columns have a maximum length of 32Kbytes (32768) bytes.
BLOB columns can contain up to 4 gbytes of data. They need to be broken down into 32767 byte 'chunks' if the BLOB contains more than 32k of data. Note: htp.p will not error if you pass it more than 32k of data. It prints the first 32k and ignore the rest.

htp.prn(utl_raw.cast_to_varchar2(buffer)); is used to convert the BLOB contents into character format for download. Note that for this to work, the NLS_LANG parameter used to start your iAS listener must be the same as the value used to start the database. For example, if your database is using the AMERICAN_AMERICA.WE8ISO8859P1 character set, you must have NLS_LANG=AMERICAN_AMERICA.WE8ISO8859P1 in your environment when you start your iAS (or Webdb) listener. Failure to do this will cause corruption during the download of binary files such as .pdf files. The downloaded file will be unusable (note: this does not affect the original file stored in the database).

*/

-- -----------------------------------------------------------------------------------
-- File Name    : https://oracle-base.com/dba/security/grant_delete.sql
-- Author       : Tim Hall
-- Description  : Grants delete on current schemas tables to the specified user/role.
-- Call Syntax  : @grant_delete (schema-name)
-- Last Modified: 28/01/2001
-- -----------------------------------------------------------------------------------
create or replace procedure download_blob(

  p_id        in  number

) is

  v_mimetype TABLE.MIME_TYPE% TYPE ;

  v_content TABLE.CONTENT% TYPE ;

  v_name TABLE.DOC_FILE_NAME% TYPE ;

  v_size        number ;

begin

  select DOC_FILE_NAME, MIME_TYPE, CONTENT, dbms_lob.getlength (CONTENT)

     into v_name, v_mimetype, v_content, v_size

   from TABLE

   where id = p_id;

  /*- The file type is set in the HTTP header. Thus the browser recognizes

  - which application (eg MS Word) to start is */

  owa_util.mime_header (nvl (v_mimetype, 'application / octet' ), false );

/* - The file size is also communicated to the browser */

  htp.p ( 'Content-length:' || v_size);

  htp.p ( 'content-disposition: attachment; filename =' || v_name);

  -- Under no circumstances should the browser remove the file from the cache.

  htp.p ( 'cache-control: must-revalidate, max-age = 0' );

  htp.p ( 'Expires: Thu, 01 Jan 1970 01:00:00 CET' );

  -- All HTTP header fields are set

  owa_util.http_header_close;

  -- This short call performs the actual file download.

  wpg_docload.download_file (v_content);

end ;
