<%@ include file="/include-internal.jsp"%>
<%@ taglib prefix="oauth" tagdir="/WEB-INF/tags/oauth" %>
<jsp:useBean id="params" class="jetbrains.buildServer.serverSide.oauth.tfs.TfsConstants"/>
<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
<jsp:useBean id="oauthConnectionBean" type="jetbrains.buildServer.serverSide.oauth.OAuthConnectionBean" scope="request"/>
<jsp:useBean id="propertiesBean" type="jetbrains.buildServer.serverSide.oauth.OAuthConnectionBean" scope="request"/>
<style type="text/css">
  tr.tfsNote table {
    width: 100%;
    border-spacing: 0;
  }

  tr.tfsNote table td {
    padding: 1px 0 1px 0;
    border: none;
  }

  table.applicationUrls {
    padding: 4px;
  }

  table.runnerFormTable input[type='password'] {
    width: 20em;
  }
</style>

<oauth:displayName/>

<c:choose>
  <c:when test="${params.types.size() == 1}">
    <c:set var="type" value="${params.types[0]}"/>
    <props:hiddenProperty name="${params.type}" value="${type.name}"/>
    <jsp:include page="/oauth/tfs/${type.editPage}"/>
  </c:when>
  <c:otherwise>
    <props:selectSectionProperty name="${params.type}" title="Authentication:" note="">
      <c:forEach items="${params.types}" var="type">
        <props:selectSectionPropertyContent value="${type.name}" caption="${type.displayName}">
          <jsp:include page="/oauth/tfs/${type.editPage}"/>
        </props:selectSectionPropertyContent>
      </c:forEach>
    </props:selectSectionProperty>
  </c:otherwise>
</c:choose>
