<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="bs" tagdir="/WEB-INF/tags" %>
<%@ taglib prefix="oauth" tagdir="/WEB-INF/tags/oauth" %>
<%@ taglib prefix="intprop" uri="/WEB-INF/functions/intprop" %>
<%@ include file="/include.jsp" %>
<%@ include file="_constants.jspf" %>

<jsp:useBean id="currentProject" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
<jsp:useBean id="readOnly" type="java.lang.Boolean" scope="request"/>

<c:set var="supportTokenPermissions" value="${intprop:getBoolean(propertySupportTokenPermissions)}"/>
<c:set var="allowShowAllTokens" value="${intprop:getBoolean(propertyAllowShowAllTokens)}"/>

<oauth:tokenObtainer/>
<style type="text/css">
  .readOnlyNote {
    display: none;
  }
</style>

<script type="text/javascript">
  BS.TokenManagement = {
    getComponent() {
      return '${componentListTokens}';
    },
    getParams() {
      return {
        projectId: '${currentProject.externalId}',
        projectName: '<bs:forJs>${currentProject.name}</bs:forJs>',
        supportTokenPermissions: ${supportTokenPermissions},
        allowShowAllTokens: ${allowShowAllTokens},
        readOnly: ${readOnly}
      }
    }
  };
</script>

<%@ include file="_frontendBundleSupport.jspf"%>