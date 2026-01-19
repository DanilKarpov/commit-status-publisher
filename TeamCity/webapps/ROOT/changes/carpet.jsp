<%@ include file="../include-internal.jsp"%>
<c:if test="${changeDetailsBean.problemsSectionNeeded}">
  <c:set var="problemText"><%@ include file="_changeProblemSummary.jspf" %></c:set>
  <jsp:useBean id="cachedChangeStatus" type="jetbrains.buildServer.controllers.changes.OneChangeStatus" scope="request"/>
  <jsp:setProperty name="cachedChangeStatus" property="statusText" value="${problemText}"/>
</c:if>

<script>
    BS.changeTree.updateCarpetAndStatusText('ct_node_${carpetId}', ${configurationStatusMapJson},
        ${changeDetailsBean.bigProblem}, '<bs:forJs>${problemText}</bs:forJs>');
</script>
