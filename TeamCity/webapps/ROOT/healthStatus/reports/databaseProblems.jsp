<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="healthStatusItem" type="jetbrains.buildServer.serverSide.healthStatus.HealthStatusItem" scope="request"/>
<c:choose>
  <c:when test="${healthStatusItem.additionalData['internalDbInUse']}">
    <c:set var="dbSize" value="${healthStatusItem.additionalData['databaseSize']}"/>
    <c:if test="${healthStatusItem.additionalData['criticalSize']}">
      The server currently uses the internal database whose size has grown over the warning level and is already <strong>${util:formatFileSize(dbSize,2)}</strong>.
      To achieve better performance and reliability, switching to a standalone database is strongly recommended.<bs:help file="Setting up an External Database"/>
    </c:if>
    <c:if test="${not healthStatusItem.additionalData['criticalSize']}">
      The server currently uses the internal database.
      For production purposes, it is recommended to use a standalone database which provides better performance and reliability.<bs:help file="Setting up an External Database"/>
    </c:if>
  </c:when>
  <c:when test="${not empty healthStatusItem.additionalData['MyISAMTables']}">
    <c:set var="myISAMTables" value="${healthStatusItem.additionalData['MyISAMTables']}"/>
    <c:set var="numMyISAMTables" value="${fn:length(myISAMTables)}"/>
    <strong>${numMyISAMTables}</strong> table<bs:s val="${numMyISAMTables}"/> in the MySQL database currently use${numMyISAMTables == 1 ? 's' : ''} <a href="http://dev.mysql.com/doc/refman/5.5/en/myisam-storage-engine.html" target="_blank" rel="noreferrer">MyISAM storage engine</a>.
    To achieve better performance, switching to <a href="http://dev.mysql.com/doc/refman/5.5/en/innodb-storage-engine.html" target="_blank" rel="noreferrer">the InnoDB storage engine</a> is recommended.
    For instructions on converting MyISAM tables to InnoDB, refer to <a href="http://dev.mysql.com/doc/refman/5.5/en/converting-tables-to-innodb.html" target="_blank" rel="noreferrer">the MySQL documentation</a>.
    Make sure you read <bs:helpLink file="How+To..." anchor="ConfigureNewlyInstalledMySQLServer">our recommendations for configuring MySQL</bs:helpLink>

    <div style="margin-top: 1em;">
      <a href="#" onclick="jQuery('#myisam_tables').toggle()">List of tables with MyISAM storage engine &raquo;</a>
    </div>

    <div id="myisam_tables" style="display: none;">
      <ul>
        <c:forEach items="${myISAMTables}" var="tn">
          <li><c:out value='${tn}'/></li>
        </c:forEach>
      </ul>
    </div>
  </c:when>
  <c:when test="${healthStatusItem.identity == 'MySQL_Time_Zone_Mismatch'}">
    The timezone used by TeamCity server and database server are different.
    Please specify the timezone of the database server using <strong>connectionProperties.serverTimezone</strong> property in the &lt;TeamCity data directory&gt;/config/database.properties file
  </c:when>
  <c:when test="${healthStatusItem.identity == 'MySQL_FlushTrxCommit'}">
    The variable <strong>innodb_flush_log_at_trx_commit</strong> in MySQL database is set to default value: <strong>1</strong>. By changing this variable you can improve performance of your TeamCity server.
    Make sure you read <bs:helpLink file="How+To..." anchor="ConfigureNewlyInstalledMySQLServer">our recommendations for configuring MySQL</bs:helpLink>.
  </c:when>
  <c:when test="${healthStatusItem.identity == 'PSQL_SynchronousCommit'}">
    The parameter <strong>synchronous_commit</strong> in PostgreSQL database is set to default value: <strong>on</strong>. By changing this parameter you can improve performance of your TeamCity server.
    Make sure you read <bs:helpLink file="How+To..." anchor="ConfigureNewlyInstalledPostgreSQLServer">our recommendations for configuring PostgreSQL</bs:helpLink>.
  </c:when>
</c:choose>