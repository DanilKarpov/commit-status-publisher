<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
<jsp:useBean id="oauthConnectionBean" type="jetbrains.buildServer.serverSide.oauth.OAuthConnectionBean" scope="request"/>
<jsp:useBean id="oauthProvider" type="jetbrains.buildServer.serverSide.oauth.OAuthProvider" scope="request"/>

<c:set var="projectId" value="${project.externalId}"/>
<c:set var="oauthTestConnectionPath" value="${oauthConnectionBean.defaultProperties['testConnectionEndpoint']}"/>
<c:url var="oauthTestConnectionUrl" value="${oauthTestConnectionPath}"/>
<c:set var="isNewConnection" value="${empty oauthConnectionBean.connectionId}"/>

<%@include file="connectionHeader.jspf"%>
<%@include file="_connectionStorageWarner.jspf"%>

<script type="application/javascript">
  {
    const $rootButtonsBlock = $j('div.popupSaveButtonsBlock:visible');
    if ($rootButtonsBlock.length > 0) {
      const $btn = $rootButtonsBlock.children('#testConnectionButton');
      $btn.remove()
    }
    <c:if test="${not empty oauthTestConnectionUrl}">
      $j(document).ready(function() {
        ConnectionProperties.showTestConnection();
      });
    </c:if>
  }
</script>

<c:if test="${not isNewConnection}">
  <c:forEach var="parameterName" items="${oauthProvider.tokenStorageParameters}">
    <script type="text/javascript">
      BS.ConnectionStorageWarner.registerForParameter('<bs:forJs>${parameterName}</bs:forJs>');
    </script>
  </c:forEach>
</c:if>

<table class="runnerFormTable" style="width: 99%;">
<jsp:include page="${oauthProvider.editParametersUrl}"/>
</table>
