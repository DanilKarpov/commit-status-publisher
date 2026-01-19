<%@ include file="../include-internal.jsp"%>
<%@ taglib prefix="ch" tagdir="/WEB-INF/tags/myChanges" %>

<jsp:useBean id="bean" scope="request" type="jetbrains.buildServer.controllers.changes.ChangesPageBean"/>

<c:set var="treeState" value="${ufn:getPropertyValue(currentUser, 'changesTreeState')}" scope="request"/>
<c:if test="${fn:contains(ufn:getPropertyValue(currentUser, 'changesTreeState'), ':c')}">
  <%-- If more than one expanded node, collapse all nodes --%>
  <c:set var="treeState" value="" scope="request"/>
</c:if>

<c:set var="showUsername" value="${param.changesOwnerId < 0 or currentUser.id < 0}"/>

<script type="text/javascript">
  <c:set var="updateGeneralData" value="${empty param['updateChanges']}"/>

  BS.ChangePreloadBlocks = [];
  <c:forEach var="jc" items="${bean.joinedChanges}">

    <c:set var="cs" value="${jc.changeStatus}"/>
    <c:set var="cs_id"><bs:_csId changeStatus="${cs}"/></c:set>
    <c:set var="cs_json"><bs:_csJson changeStatus="${cs}"/></c:set>

    BS.ChangePageData['jc_${jc.joinId}'] = {
      'updatable': ${jc.updatable},
      'lastRowRecord': ${cs_json},
      'records_with_same_builds':[]     // TBD: simplify, now always contain one record
    };
    <c:set var="nodeId">ct_node_${cs_id}</c:set>
    BS.ChangePreloadBlocks.push('${nodeId}');

    <c:if test="${updateGeneralData and not empty jc.newDate}">
      BS.ChangePage.lastDay = ${jc.newDate.time};
    </c:if>

    BS.ChangePageData['jc_${jc.joinId}'].records_with_same_builds.push(${cs_json});
    BS.changeTree.addNodeIfNotExists(new BS.ChangeNode('${nodeId}', ${cs_json}, ${cs_json}, ${fn:contains(treeState, nodeId)}));

  </c:forEach>

  <c:if test="${updateGeneralData}">
    // Update lastChanges record only if this is not "updateChanges" request
    BS.ChangePage.haveMoreChanges = ${bean.hasMoreChanges};
    <c:if test="${not empty bean.joinedChanges}">
      <c:set var="lastChangeStatus" value="${bean.joinedChanges[fn:length(bean.joinedChanges) - 1].changeStatus}"/>
      BS.ChangePage.lastRecord = <bs:_csJson changeStatus="${lastChangeStatus}"/>;
    </c:if>
  </c:if>

  <c:if test="${not empty bean.joinedChanges}">
    <c:set var="firstChangeStatus" value="${bean.joinedChanges[0].changeStatus}"/>
    if (!BS.ChangePage.firstRecord) {
      BS.ChangePage.firstRecord = <bs:_csJson changeStatus="${firstChangeStatus}"/>;
    }
  </c:if>

  <%@ include file="updateFilter.jspf"%>
  <c:forEach var="prj_data" items="${changesProjectsTabs}">
  BS.ChangePageFilter.addProject({
    id: '${prj_data.key.projectId}',
    externalId: '${prj_data.key.externalId}',
    name: '<bs:escapeForJs forHTMLAttribute="false" text="${prj_data.key.extendedFullName}"/>',
    usageCount: ${prj_data.value}
  });
  </c:forEach>
  BS.ChangePageFilter.updateFilterView();

</script>

<c:forEach var="jc" items="${bean.joinedChanges}" varStatus="status">
  <jsp:useBean id="jc" type="jetbrains.buildServer.controllers.changes.ChangeWithCarpet"/>
  <div id="jc_${jc.joinId}" class="joinedChange">

    <table class="joinedChangeTable" id="jct_<bs:_csId changeStatus="${jc.changeStatus}"/>">

      <c:set var="changeStatus" value="${jc.changeStatus}"/>
      <%@ include file="changeRow.jspf" %>

    </table>
  </div>
</c:forEach>
