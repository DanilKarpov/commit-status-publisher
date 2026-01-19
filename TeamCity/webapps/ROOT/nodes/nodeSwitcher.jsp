<%@ include file="/include-internal.jsp"%>

<jsp:useBean id="serverNodes" scope="request" type="java.util.List"/>
<jsp:useBean id="currentNode" scope="request" type="java.lang.String"/>

<c:if test="${fn:length(serverNodes) > 1}">
  <script>
    BS.Log.info("Installing current node switcher");
    ReactUI.setNodeInfo({
      currentNode: '<c:out value="${currentNode}"/>',
      serverNodes: [
        <c:forEach var="node" items="${serverNodes}">
          '<c:out value="${node}"/>',
        </c:forEach>
      ],
    });
  </script>
</c:if>
