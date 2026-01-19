<%@ include file="/include-internal.jsp"
%><jsp:useBean id="template" type="jetbrains.buildServer.serverSide.BuildTypeTemplate" scope="request"
/><c:set var="containerId" value="container_hi_${template.externalId}"
/><c:url
    var="refreshUrl"
    value="/admin/buildTypeTemplateHealthStatusItems.html?templateId=${template.externalId}&compute=true&excludeCategoryId=${excludeCategoryId}&originUrl=${util:urlEscape(param.originUrl)}"
/><bs:refreshable containerId="${containerId}" pageUrl="${refreshUrl}"
  ><c:if test="${results != null and not empty results}">
    <c:set var="pageUrl" scope="request" value="${param.originUrl}"/>
    <bs:healthReportIcon items="${results}" currentEntity="${template}" project="${template.project}"/>
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