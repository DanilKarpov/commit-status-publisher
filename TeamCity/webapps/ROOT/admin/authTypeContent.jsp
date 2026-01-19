<%@ include file="/include-internal.jsp"
%><jsp:useBean id="type" type="jetbrains.buildServer.serverSide.auth.AuthModuleType" scope="request"/>

<c:choose>
  <c:when test="${empty type}"><span>Authentication module not found</span></c:when>
  <c:otherwise>
    <span class="grayNote"><c:out value="${type.description}"/></span>
    <c:if test="${not empty type.editPropertiesJspFilePath}">
      <div style="margin-top: 1em;">
        <jsp:include page="${type.editPropertiesJspFilePath}"/>
      </div>
    </c:if>
  </c:otherwise>
</c:choose>
