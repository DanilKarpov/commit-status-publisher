<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="project" type="jetbrains.buildServer.serverSide.SProject" scope="request"/>
<jsp:useBean id="suggestionsMode" type="java.lang.Boolean" scope="request"/>
<%--@elvariable id="project" type="jetbrains.buildServer.serverSide.SProject"--%>
<c:set var="containerId" value="container_hi_${project.externalId}"/>
<c:set var="adminArea" value="${fn:contains(pageUrl, '/admin/')}"/>
<c:url
  var="refreshUrl"
  value="${adminArea ? '/admin' : ''}/projectHealthStatusItems.html?projectId=${project.externalId}&compute=true&excludeCategoryId=${excludeCategoryId}&originUrl=${util:urlEscape(param.originUrl)}"
/>
<bs:refreshable containerId="${containerId}" pageUrl="${refreshUrl}">
  <c:if test="${results != null and not empty results}">
    <c:set var="pageUrl" scope="request" value="${param.originUrl}"/>
    <bs:healthReportIcon items="${results}" currentEntity="${project}" project="${project}"/>
  </c:if>
  <c:if test="${adminArea == false and (results == null or empty results)}">
    <span style="display: none">No items to show</span>
  </c:if>
  <c:if test="${results == null}">
    <script type="text/javascript">
      window.setTimeout(function() {
        var container = document.getElementById('${containerId}');
        if (container != null) {
          container.refresh();
        }
      }, 300);
    </script>
  </c:if>
</bs:refreshable>