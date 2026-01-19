<%@ include file="/include-internal.jsp"%>
<jsp:useBean id="auditLogData" scope="request" type="jetbrains.buildServer.controllers.audit.AuditLogData"/>

<style>
  .comboBox {
    display: inline-block;
    max-width: 330px;
    margin-right: 10px;
  }
</style>
<form action="<c:url value="/admin/audit.html"/>" method="post" id="auditLogFilterForm" onsubmit="BS.AuditLogFilterForm.submit(); return false;">
  <div class="actionBar">
    <span class="actionBarRight">
      <label for="actionsPerPage">Results per page:</label>&nbsp;
      <select id="actionsPerPage" name="actionsPerPage" onchange="BS.AuditLogFilterForm.submit();">
        <admin:_actionsPerPageOption value="10" auditLogData="${auditLogData}"/>
        <admin:_actionsPerPageOption value="20" auditLogData="${auditLogData}"/>
        <admin:_actionsPerPageOption value="50" auditLogData="${auditLogData}"/>
        <admin:_actionsPerPageOption value="100" auditLogData="${auditLogData}"/>
        <admin:_actionsPerPageOption value="200" auditLogData="${auditLogData}"/>
        <admin:_actionsPerPageOption value="500" auditLogData="${auditLogData}"/>
      </select>
      <input type="hidden" name="reset" id="reset"/>
    </span>

    <span class="nowrap">
      <label class="firstLabel" for="actionTypeSet">Show:</label>
      <forms:select id="actionTypeSet" name="actionTypeSet" className="comboBox" enableFilter="true" filterOptions="{maxWidth: 175}">
        <c:forEach items="${auditLogData.actionTypeSets}" var="actionTypeSet">
          <c:set var="optionFullName"><c:out value="${actionTypeSet.fullName}"/></c:set>
          <option data-title="${optionFullName}"
                  <c:if test="${auditLogData.selectedActionTypeSetIdAsString == actionTypeSet.id}">selected="true"</c:if>
                  value="${actionTypeSet.id}"
                  class="<c:if test='${actionTypeSet.group}'>optgroup </c:if>user-depth-${actionTypeSet.limitedDepth}"
              >
            <c:out value="${actionTypeSet.name}"/>
          </option>
        </c:forEach>
      </forms:select>
    </span>

    <span class="nowrap">
      <label for="filterScopeId">in:</label>
      <input name="filterScopeId" id="filterScopeId" value="<c:out value='${auditLogData.filterScopeId}'/>" type="hidden"/>
      <div style="width: 330px; display: inline-block; vertical-align: top; margin-right: 10px;">
         <div id="buildTypeSelector" class="comboBox" style="width: 330px;"></div>
         <div id="includeScopeHierarchyDiv" style="display: none">
           <input type="checkbox" name="includeScopeHierarchy" id="includeScopeHierarchy" ${auditLogData.includeScopeHierarchy ? "checked=checked" : ""} unchecked-value="false"/>
           <label for="includeScopeHierarchy">show subprojects activity</label>
         </div>
      </div>

      <script>
        {
          let selected = null;
          <c:if test="${auditLogData.filterScopeIdFilterApplied}">
            <c:forEach items="${auditLogData.filterScopes}" var="filterScope">
              <c:if test="${auditLogData.filterScopeId == filterScope.id}">
                const idRE = /^(buildType|project)_(.*)$/;
                const parsedId = '${filterScope.id}'.match(idRE);
                if (parsedId !== null) {
                  var type = parsedId[1];
                  if (type === 'buildType') {
                    type = 'bt';
                  }
                  var id = parsedId[2];

                  selected = {
                    nodeType: type,
                    id: id,
                  };
                }
              </c:if>
            </c:forEach>
            <c:if test="${auditLogData.projectIdFilterApplied}">
              $("includeScopeHierarchyDiv").show();
            </c:if>
          </c:if>
          <c:if test="${!auditLogData.filterScopeIdFilterApplied}">
            $("includeScopeHierarchy").checked = true;
          </c:if>
          ReactUI.renderConnected(document.getElementById('buildTypeSelector'), ReactUI.ProjectBuildTypeSelect, {
            allItemName: 'Everywhere',
            allItemSelectable: true,
            expandAll: true,
            includeRoot: true,
            selected,
            onSelect(item) {
              let filterScopeId;
              switch (item.nodeType) {
                case 'project':
                  filterScopeId = 'project_' + item.id;
                  $("includeScopeHierarchyDiv").show();
                  break;
                case 'bt':
                  filterScopeId = 'buildType_' + item.id;
                  $("includeScopeHierarchyDiv").hide();
                  break;
                default:
                  filterScopeId = -1;
                  $("includeScopeHierarchyDiv").hide();
              }
              $j('#filterScopeId').val(filterScopeId);
            }
          });
        }
      </script>
    </span>

    <span class="nowrap">
      <label for="userId">by:</label>
      <forms:select id="userId" name="userId" className="comboBox" enableFilter="true" filterOptions="{maxWidth: 175}">
        <option <c:if test="${!auditLogData.userIdFilterApplied}">selected="true"</c:if> value="-1"><c:out value="All users"/></option>
        <c:forEach items="${auditLogData.users}" var="user">
          <option <c:if test="${auditLogData.selectedUserId == user.id}">selected="true"</c:if> value="${user.id}"><c:out value="${user.descriptiveName}"/></option>
        </c:forEach>
      </forms:select>
    </span>

    <div style="display: inline-block; min-width: 76px;">
      <forms:filterButton/>
      <c:if test="${auditLogData.filterApplied}"><forms:resetFilter resetHandler="BS.AuditLogFilterForm.clearFilter();"/></c:if>
      <forms:saving id="auditLogFilterApplyingProgressIcon" className="progressRingInline"/>
    </div>
  </div>

  <div id="auditPermalink">
    <admin:_auditLogPermalink data="${auditLogData}"/>
  </div>
</form>
