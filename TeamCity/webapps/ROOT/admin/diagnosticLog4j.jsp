<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core"%>
<%@ include file="/include-internal.jsp" %>

<jsp:useBean id="bean" type="jetbrains.buildServer.diagnostic.web.DiagnosticLog4jConfigController.Log4jConfigBean" scope="request"/>
<bs:fileBrowsePage id="log4jConfig"
                   dialogId="addLog4jConfig"
                   dialogTitle="Upload New Preset"
                   bean="${bean}"
                   actionPath="/admin/log4jConfig.html"
                   homePath="/admin/admin.html?item=diagnostics&tab=log4j"
                   pageUrl="${pageUrl}"
                   jsBase="BS.Log4Config">
  <jsp:attribute name="belowFileName"></jsp:attribute>
  <jsp:attribute name="headMessage">
    Choose a preset file:
  </jsp:attribute>
  <jsp:attribute name="headMessageNoFiles">
    No logging presets available
  </jsp:attribute>
</bs:fileBrowsePage>
