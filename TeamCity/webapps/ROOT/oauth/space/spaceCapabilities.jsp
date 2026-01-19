<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ include file="/include-internal.jsp" %>

<jsp:useBean id="project" scope="request" type="jetbrains.buildServer.serverSide.SProject"/>
<jsp:useBean id="connectionId" scope="request" type="java.lang.String"/>
<jsp:useBean id="capabilities" scope="request" type="java.util.List"/>
<jsp:useBean id="isPendingConnection" scope="request" type="java.lang.Boolean"/>
<jsp:useBean id="canEditProject" scope="request" type="java.lang.Boolean"/>
<jsp:useBean id="connectionTypeDescription" scope="request" type="java.lang.String"/>

<%--@elvariable id="authorizationsUrl" type="java.lang.String"--%>

<jsp:include page="spaceConnectionsService.jsp"/>

<c:set var="idContainerPrefix" value="spaceCapabilities_"/>
<c:set var="idContainer" value="${idContainerPrefix}${project.projectId}_${connectionId}"/>
<c:set var="idActionPrefix" value="refreshAction_"/>
<c:set var="idAction" value="${idActionPrefix}${project.projectId}_${connectionId}"/>
<c:set var="idActionColumnPrefix" value="refreshActionColumn_"/>
<c:set var="idWaiterPrefix" value="refreshWaiter_"/>
<c:set var="idWaiter" value="${idWaiterPrefix}${project.projectId}_${connectionId}"/>
<c:set var="idCapabilityInfoPrefix" value="capabilityInfo_"/>
<c:set var="idCapabilityInfo" value="${idCapabilityInfoPrefix}${project.projectId}_${connectionId}"/>

<script type="text/javascript">
  if (!BS.SpaceCapabilities) {
    BS.SpaceCapabilities = {
      refreshCapabilities: function (projectId, connectionId) {
        $(this.scopedId('${idActionPrefix}', projectId, connectionId)).hide();
        $(this.scopedId('${idCapabilityInfoPrefix}', projectId, connectionId)).hide();
        $(this.scopedId('${idWaiterPrefix}', projectId, connectionId)).show();

        var that = this;
        BS.SpaceConnectionsService.evictApplicationInfo({
          projectId: projectId,
          connectionId: connectionId,
          onSuccess: function () {
            $(that.scopedId('${idContainerPrefix}', projectId, connectionId)).refresh(null, null, () => that.injectRefreshAction(projectId, connectionId, false));
          },
          onFailure: function () {
            TeamCityAPI.Services.AlertService.addAlert("Refresh failed", "error");
          }
        });
      },

      injectRefreshAction: function (projectId, connecdtionId, initial) {
        const actionColumnId = this.scopedId('${idActionColumnPrefix}', projectId, connecdtionId);
        const actionElement = $j('#' + this.scopedId('${idActionPrefix}', projectId, connecdtionId));
        const tr = actionElement.closest('tr');
        if (initial) {
          const td = tr.find('td.capability-action').first();
          td.attr('id', actionColumnId)
          .append(actionElement);
        } else {
          $j('#' + actionColumnId).empty().append(actionElement);
        }
      },

      scopedId: function (idPrefix, projectId, connectionId) {
        return idPrefix + projectId + '_' + connectionId;
      }
    };
  }

  $j(document).ready(function() {
    BS.SpaceCapabilities.injectRefreshAction('${project.projectId}', '${connectionId}', true);
  });

  $j('.authorizationsAnchor').on('click', (event) => event.stopPropagation());
</script>

<bs:refreshable containerId="${idContainer}" pageUrl="${pageUrl}">
  <div id="${idCapabilityInfo}">

    <div>Type: ${connectionTypeDescription}</div>

    <c:choose>
      <c:when test="${empty capabilities}">
        <div>The associated Space application has no permissions.</div>
      </c:when>
      <c:otherwise>
        <div>
          Capabilities:
          <ul style="margin: 0;">
            <c:forEach var="description" items="${capabilities}">
              <li><c:out value="${description}"/></li>
            </c:forEach>
          </ul>
        </div>
      </c:otherwise>
    </c:choose>

    <c:if test="${isPendingConnection}">
      <bs:buildStatusIcon type="red-sign" className="warningIcon"/> Is waiting for requested connection rights to be <a class="authorizationsAnchor"
                                                                                                                        href="<c:out value="${authorizationsUrl}"/>"
                                                                                                                        rel="noopener noreferrer"
                                                                                                                        target="_blank">granted at Space</a>.
    </c:if>
  </div>
  <c:if test="${canEditProject}">
    <span>
      <forms:saving id="${idWaiter}" style="float: none;"/>
      <bs:actionIcon id="${idAction}"
                     name="update"
                     onclick="BS.SpaceCapabilities.refreshCapabilities('${project.projectId}', '${connectionId}'); return false"
                     title="Refresh connection capabilities"/>
    </span>
  </c:if>
</bs:refreshable>