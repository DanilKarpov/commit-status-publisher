<%@ include file="/include-internal.jsp" %>
<%@ taglib prefix="admin" tagdir="/WEB-INF/tags/admin" %>
<jsp:useBean
        id="dashboards"
        type="java.util.Map<java.lang.String, jetbrains.buildServer.serverSide.deploymentDashboards.entities.DeploymentDashboard>"
        scope="request"
/>
<jsp:useBean id="project" scope="request" type="jetbrains.buildServer.serverSide.SProject"/>

<script type="text/javascript">
    BS.DeploymentDashboards = {
        removeDashboard: function(projectId, dashboardId) {
            if (!confirm("Are you sure you want to remove this dashboard?")) return false;

            BS.ajaxRequest('${Constants.Companion.dashboardRemoveEndpoint}', {
                    method: "post",
                    parameters: "dashboardId=" + dashboardId + "&projectId=" + projectId,
                    onComplete: function () {
                        BS.reload();
                    }
                }
            );

            return false;
        }
    };

    BS.CreateDashboardDialog = OO.extend(BS.AbstractWebForm, OO.extend(BS.AbstractModalDialog, {
        getContainer: function () {
            return $('createDashboardDialog');
        },

        showDialog: function() {
            this.cleanFields();
            this.clearErrors();
            this.showCentered();
        },

        /**
         * Will validate on server
         */
        validate: function() {
            this.setSaving(true);
            this.closeAndRefresh();
            return true;
        },

        cleanFields: function() {
            $j("#dashboardId").val('');
            $j("#dashboardName").val('');
        },

        closeAndRefresh: function() {
            this.close();
            BS.reload(true);
        }
    }));
</script>

<div class="section noMargin">
    <h2 class="noBorder">Deployment Dashboards</h2>
    <bs:smallNote>Deployment dashboard may be used to show the remote deployments statuses<bs:help file="Deployment+Dashboard"/></bs:smallNote>

    <bs:messages key="dashboardRemoved"/>
    <bs:messages key="dashboardCreated"/>

    <authz:authorize allPermissions="EDIT_PROJECT" projectId="${project.projectId}">
        <forms:addButton id="addDashboard" onclick="BS.CreateDashboardDialog.showDialog(); return false">Add dashboard</forms:addButton>
    </authz:authorize>

    <c:set var="dashboardsCount" value="${fn:length(dashboards)}"/>
    <p>
        There <bs:are_is val="${dashboardsCount}"/> <strong>${dashboardsCount}</strong> dashboard<bs:s val="${dashboardsCount}"/> defined in the current project
    </p>

    <c:if test="${dashboardsCount gt 0}">
        <c:set var="canEditProject" value="${afn:permissionGrantedForProject(project, 'EDIT_PROJECT')}"/>
        <l:tableWithHighlighting id="dashboardsTable" className="parametersTable">
            <thead>
            <tr>
                <th class="dashboardId">Dashboard ID</th>
                <th class="dashboardName" colspan="3">Name</th>
            </tr>
            </thead>
            <tbody>
            <c:forEach var="dashboardEntry" items="${dashboards}">
                <tr data-id="${dashboardEntry.key}">
                    <td>
                        <c:out value="${dashboardEntry.key}"/>
                    </td>
                    <td>
                        <div><c:out value="${dashboardEntry.value.name}"/></div>
                    </td>
                    <c:if test="${canEditProject}">
                        <td class="runnerActions highlight edit">
                            <bs:actionsPopup controlId="actions${dashboardEntry.key}"
                                             popup_options="shift: {x: -150, y: 20}, className: 'quickLinksMenuPopup'">
                              <jsp:attribute name="content">
                                <div>
                                    <ul class="menuList">
                                        <l:li>
                                            <a href="#"
                                               onclick="return BS.DeploymentDashboards.removeDashboard('${project.externalId}', '${dashboardEntry.key}')">
                                               Remove dashboard...
                                            </a>
                                        </l:li>
                                    </ul>
                                </div>
                              </jsp:attribute>
                            </bs:actionsPopup>
                        </td>
                    </c:if>
                </tr>
            </c:forEach>
            </tbody>
        </l:tableWithHighlighting>
    </c:if>
</div>

<c:url var="action" value="/app/rest/deploymentDashboards"/>
<bs:dialog dialogId="createDashboardDialog"
           dialogClass="modalDialog_small"
           title="Create Dashboard"
           closeCommand="BS.CreateDashboardDialog.close()">
    <forms:multipartForm id="createDashboardForm" targetIframe="hidden-iframe" onsubmit="return BS.CreateDashboardDialog.validate();">
        <table class="runnerFormTable">
            <tr>
                <th><label for="dashboardName">Dashboard name:</label></th>
                <td>
                    <forms:textField name="dashboardName" value="" />
                </td>
            </tr>
            <tr>
                <th><label for="dashboardId">Dashboard ID:</label></th>
                <td>
                    <forms:textField name="dashboardId" value="" />
                </td>
            </tr>
        </table>
        <input type="hidden" name="projectId" value="${project.externalId}"/>
        <div class="popupSaveButtonsBlock">
            <forms:submit label="Save"/>
            <forms:cancel onclick="BS.CreateDashboardDialog.close()"/>
        </div>
    </forms:multipartForm>
</bs:dialog>