<%@ include file="/include-internal.jsp" %>
<jsp:useBean id="mainNode" type="java.lang.Boolean" scope="request"/>
<jsp:useBean id="mainNodeId" type="java.lang.String" scope="request"/>

<bs:refreshable containerId="importProjects" pageUrl="${pageUrl}">

  <c:choose>
    <c:when test="${not mainNode}">
      <div class="attentionComment">
        Projects import is not available on a secondary node. Please switch to the main node<c:if test="${not empty mainNodeId}"> (node id: <c:out value="${mainNodeId}"/>)</c:if>.
      </div>
    </c:when>
    <c:when test="${selectArchiveStep != null}">
      <jsp:include page="selectArchiveStep.jsp"/>
    </c:when>
    <c:when test="${configureImportStep != null}">
      <jsp:include page="configureImportStep.jsp"/>
    </c:when>
    <c:when test="${importProgressStep != null}">
      <jsp:include page="importProgressStep.jsp"/>
    </c:when>
  </c:choose>

</bs:refreshable>

