script

var Runtime = Java.type("java.lang.Runtime");
var System = Java.type("java.lang.System");
var Integer = Java.type("java.lang.Integer");

var FileOutputStream = Java.type("java.io.FileOutputStream");
var ByteArrayOutputStream = Java.type("java.io.ByteArrayOutputStream");
var BufferedOutputStream = Java.type("java.io.BufferedOutputStream");

var Files = Java.type("java.nio.file.Files");
var Path = Java.type("java.nio.file.Path");
var File = Java.type("java.io.File");

var executeSql = System.getenv("QSH_EXECUTE_QUERY");
var qshPager = System.getenv("QSH_PAGER_COMMAND");
var maxResultSize = System.getenv("QSH_SQLCL_MAX_RESULT_SIZE");
var tty = System.getenv("QSH_TTY");

var executeSqlFile = new File(executeSql);
if (!executeSqlFile.exists()) {
  executeSqlFile.createNewFile();

  sqlcl.setStmt("append qsh (sqlcl) - INITIALIZED");
  sqlcl.run();
  
  sqlcl.setStmt("edit " + executeSql + "");
  sqlcl.run();
} else {
  var sqlFile = Path.of(executeSql);
  var sql = Files.readString(sqlFile);

  var tempPath = Files.createTempFile("qsh-result", ".data");
  try {
    var bout = new ByteArrayOutputStream();
    sqlcl.setOut(new BufferedOutputStream(bout));

    ctx.putProperty("script.runner.setpagesize", Integer.parseInt(maxResultSize));
    sqlcl.setStmt(sql);
    sqlcl.run();

    var fileOutputStream = new FileOutputStream(tempPath.toFile());
    bout.writeTo(fileOutputStream);
    fileOutputStream.close();

    var pager = Runtime.getRuntime().exec(
      [ "sh", "-c", "'" + qshPager + "' '" + tempPath.toString() + "' < " + tty + " > " + tty ]
    );
    pager.waitFor();
  } finally {
    Files.delete(tempPath);
  }
}
/

