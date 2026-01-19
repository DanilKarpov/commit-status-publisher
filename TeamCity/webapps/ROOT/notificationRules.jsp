<%@ page import="jetbrains.buildServer.web.util.WebUtil" %>
<%@ include file="include-internal.jsp" %>
<%@ taglib prefix="profile" tagdir="/WEB-INF/tags/userProfile" %>
<jsp:useBean id="currentUser" type="jetbrains.buildServer.users.User" scope="request"/>
<jsp:useBean id="notificationRulesForm" type="jetbrains.buildServer.controllers.profile.notifications.NotificationRulesForm" scope="request"/>
<jsp:useBean id="pageUrl" type="java.lang.String" scope="request"/>
<jsp:useBean id="editingPersonalRules" type="java.lang.Boolean" scope="request"/>
<c:set var="inheritedRulesMap" value="${notificationRulesForm.inheritedRules}"/>
<c:set var="groups" value="<%=notificationRulesForm.getInheritedRules().keySet()%>"/>
<%--@elvariable id="detailsFragment" type="java.lang.Boolean"--%>
<%--@elvariable id="rulesAvailable" type="java.lang.Boolean"--%>
<%--@elvariable id="filteredForm" type="java.lang.Boolean"--%>
<%--@elvariable id="detailsFragmentDescription" type="java.lang.String"--%>
<%--@elvariable id="showAll" type="java.lang.Boolean"--%>

<bs:linkScript>
  /js/bs/blocks.js
  /js/bs/blockWithHandle.js
  /js/bs/collapseExpand.js
  /js/bs/notificationRules.js
</bs:linkScript>

<div id="notificationRuleFormScriptsHolder"></div>

<script>
  if (typeof BS.NotificationRuleForm === 'undefined') {
    <%-- this case serves for the case on build features page where it's impossible to include js libraries
    with standard bs:linkScript tag --%>
    var jsUrls = [
      "<c:url value='/js/bs/blocks.js'/>",
      "<c:url value='/js/bs/blockWithHandle.js'/>",
      "<c:url value='/js/bs/collapseExpand.js'/>",
      "<c:url value='/js/bs/notificationRules.js'/>"
    ];

    for (var i = 0; i < jsUrls.length; i++) {
      $j("#notificationRuleFormScriptsHolder").append(
        "<script type='text/javascript/' src='" + jsUrls[i] + "'/>"
      );
    }
  }

  var cssUrl = "<c:url value='/css/notificationRules.css'/>";

  $j("#notificationRuleFormScriptsHolder").append(
    "<link rel='stylesheet' href='" + cssUrl + "' />"
  );
</script>

<script>
  BS.NotificationRuleForm.setNotificatorType('<%=WebUtil.encode(notificationRulesForm.getNotificatorType())%>');
  BS.NotificationRuleForm.setHolderId('${notificationRulesForm.editeeId}');
  BS.NotificationRuleForm.setFilter('${notificationRulesForm.filterType}', '${notificationRulesForm.filter}');
</script>

<div class="settingsBlock">
  <c:if test="${editingPersonalRules}">
    <c:if test="${not empty inheritedRulesMap and not filteredForm}">
      <div class="settingsBlockTitle">Own rules</div>
    </c:if>
    <c:if test="${filteredForm}">
      <div class="settingsBlockTitle">
        <c:choose>
          <c:when test="${empty notificationRulesForm.notificationsRules}">No own rules configured for ${detailsFragmentDescription}</c:when>
          <c:otherwise>Showing rules affecting ${detailsFragmentDescription}</c:otherwise>
        </c:choose>
      </div>
    </c:if>
    <c:if test="${notificationRulesForm.hiddenCount > 0}">
      <div class="settingsBlockTitleHint">
        You do not have permissions to see ${notificationRulesForm.hiddenCount} more <bs:plural txt="rule" val="${notificationRulesForm.hiddenCount}"/>
      </div>
    </c:if>

    <c:if test="${not notificationRulesForm.canEditRules and not empty notificationRulesForm.notificationsRules}">
      <n:readOnlyRules rules="${notificationRulesForm.notificationsRules}"/>
    </c:if>
  </c:if>

  <c:if test="${notificationRulesForm.canEditRules || !editingPersonalRules}">
    <c:if test="${editingPersonalRules}">
      <c:set var="canEditOrder" value="${afn:permissionGrantedGlobally('CHANGE_USER_NOTIFICATIONS_IN_PROJECT')}"/>
      <c:if test="${fn:length(notificationRulesForm.notificationsRules) > 1 and canEditOrder}">
        <div class="draggableMessage">Use drag-and-drop to reorder the rules. The first matching rule will apply.</div>
      </c:if>

      <div class="messagesHolder">
        <div id="savingData"><i class="icon-refresh icon-spin ring-loader-inline"></i> Saving...</div>
        <div id="dataSaved">New notification rules order applied</div>
        <bs:messages key="ruleUpdated" style="margin: 0em;"/>
        <bs:messages key="ruleAdded" style="margin: 0em;"/>
        <bs:messages key="ruleDeleted" style="margin: 0em;"/>
      </div>

      <c:if test="${not empty notificationRulesForm.notificationsRules}">
        <c:set var="idsIndex">1</c:set>

        <div class="rulesWrapper <c:if test="${detailsFragment}">rulesDetails</c:if>">
          <table class="dark rulesTable">
            <thead>
            <tr class="header">
              <th class="dragHandle"><img src="<c:url value='/img/empty.png'/>" alt="" width="16" height="16" class="invisible" data-no-retina/></th>
              <th class="moveTop"><img src="<c:url value='/img/empty.png'/>" alt="" width="16" height="16" class="invisible" data-no-retina/></th>
              <th class="builds">Watching</th>
              <th class="condition">Send notification when</th>
              <th class="edit"><span style="visibility:hidden;">Edit</span></th>
              <th class="remove"><span style="visibility:hidden;">Delete</span></th>
            </tr>
            </thead>
          </table>

          <div id="notificationRulesRows">
            <c:set var="editing">${not empty notificationRulesForm.editingRule}</c:set>
            <c:forEach items="${notificationRulesForm.notificationsRules}" var="rule" varStatus="pos">
              <c:set var="canEdit" value="${rule.canEdit}"/>
              <div
                  class="<c:if test="${canEditOrder}">draggable tc-icon_draggable</c:if> notificationRule tc-icon_before icon16 <%--<c:if test="${not empty notificationRulesForm.filter and rule.notEffective}">disabledRule</c:if>--%> <c:choose>
             <c:when test="${editing and notificationRulesForm.editingRule.id == rule.id}">draggableEditingRow</c:when>
             <c:when test="${not editing and rule.addedOrEdited}">draggableChangedRow</c:when>
           </c:choose>" id="rule_${rule.id}">
                <jsp:useBean id="rule" type="jetbrains.buildServer.controllers.profile.notifications.NotificationRulesForm.EditableNotificationRule"/>
                <table class="dark rulesTable">
                  <tr>
                    <td class="moveTop">
                      <c:if test="${canEditOrder}">
              <span id="id_${idsIndex}"
                    class="tc-icon icon16 tc-icon_move-top moveToTopAction"
                    <c:if test="${pos.first}">style='visibility:hidden'</c:if>
                    onclick="BS.NotificationRuleForm.moveToTop('id_${idsIndex}')"
                    alt="Move to top"></span>
                        <c:set var="idsIndex">${idsIndex + 1}</c:set>
                      </c:if>
                    </td>
                    <td class="builds">
                      <n:watchedBuilds rule="${rule}"/>
                    </td>
                    <td class="condition">
                      <n:eventsList rule="${rule}"/>
                    </td>
                    <td class="edit">
                      <c:set var="onclick">BS.NotificationRuleForm.editRule('<c:url value='/notificationRules.html'/>', 'id_${idsIndex}')</c:set>
                      <a
                          <c:if test="${not canEdit}">class="hidden"</c:if> id="id_${idsIndex}" href="#" onclick="${onclick}; return false" class="editRuleAction">Edit</a>
                      <c:set var="idsIndex">${idsIndex + 1}</c:set>
                    </td>
                    <td class="remove" title="Remove rule">
                      <a
                          <c:if test="${not canEdit}">class="hidden"</c:if> id="id_${idsIndex}" href="#"
                          onclick="BS.NotificationRuleForm.removeRule('<c:url value='/notificationRules.html'/>', 'id_${idsIndex}'); return false"
                          class="deleteRuleAction">Delete</a>
                      <c:set var="idsIndex">${idsIndex + 1}</c:set>
                    </td>
                  </tr>
                </table>
              </div>
            </c:forEach>
          </div>
        </div>
      </c:if>
    </c:if>

    <c:if test="${empty ruleBean or not ruleBean.newRule}">
      <div>
        <c:if test="${not detailsFragment and
                fn:startsWith(notificationRulesForm.editeeId, 'user:') and
                (fn:length(notificationRulesForm.notificationsRules) > 0 or fn:length(groups) > 0) and
                editingPersonalRules
                }">
          <div class="smallNote" style="margin-left: 0; margin-bottom: .5em;">
            To unsubscribe from group notifications, add your own rule with the same watched builds and different notification events.
            To unsubscribe from all events, add a rule with the corresponding watched builds and no events selected.<bs:help file="Adding+Notification+Rules"/>
          </div>
        </c:if>
        <c:url value='/notificationRules.html' var="editRuleUrl"/>
        <c:if test="${editingPersonalRules}">
          <forms:addButton onclick="BS.NotificationRuleForm.editRule('${editRuleUrl}', null); return false" additionalClasses="addRuleButton">Add new rule</forms:addButton>
        </c:if>
      </div>
    </c:if>

    <c:choose>
      <c:when test="${editingPersonalRules}">
        <c:if test="${not empty ruleBean}">
          <a name="ruleEditingForm" id="ruleEditingForm"></a>
          <jsp:include page="/notificationRuleForm.jsp"/>
        </c:if>
      </c:when>
      <c:otherwise>
        <jsp:include page="/buildTypeNotificationRuleForm.jsp"/>
      </c:otherwise>
    </c:choose>
  </c:if>
</div>

<br/>

<c:if test="${not empty inheritedRulesMap}">
  <div class="settingsBlock">
    <div class="settingsBlockTitle">Inherited rules</div>

    <table class="rulesTable inheritedRulesTable dark">
      <thead>
      <tr class="header">
        <th class="group">Group</th>
        <th class="builds">Watching</th>
        <th class="condition">Send notification when</th>
      </tr>
      </thead>
      <c:forEach items="${groups}" var="group">
        <c:set var="inheritedRules" value="${inheritedRulesMap[group]}"/>
        <c:if test="${not empty inheritedRules}">
          <c:forEach items="${inheritedRules}" var="rule" varStatus="ruleStatus">
            <tr>
              <c:if test="${ruleStatus.first}">
                <td rowspan="${fn:length(inheritedRules)}" class="group">
                  <bs:editGroupLink group="${userGroupMapper.getUserGroupDto(group)}"><strong><c:out value="${group.name}"/></strong></bs:editGroupLink>
                  <c:if test="${not empty group.description}">
                    <div class="group-description"><c:out value="${group.description}"/></div>
                  </c:if>
                </td>
              </c:if>
              <td class="watchedBuilds">
                <n:watchedBuilds rule="${rule}"/>
              </td>
              <td class="events">
                <n:eventsList rule="${rule}"/>
              </td>
            </tr>
          </c:forEach>
        </c:if>
      </c:forEach>
    </table>
  </div>
</c:if>


<script type="text/javascript">
  $j(function () {

    BS.NotificationRuleForm.enableSaving();

    $j(document).on('click', '#mergedNotificationsTree tr', function (event) {
      var $placeholder = $j(event.currentTarget).find('.placeholder');
      if ($placeholder.length > 0) {
        var type = $placeholder.data('type');
        var id = $placeholder.data('id');

        if ($j('#notificationRulesRows .draggable').length > 1) {
          Sortable.destroy('notificationRulesRows');
        }
        $('notificationDetailsContainer').refresh(null, 'filterType=' + type + '&filter=' + id, function () {
          BS.NotificationRuleForm.enableSaving();
          $j('#showAll').hide();
        });
      }
      return false;
    });
    $j(document).on('click', '#resetFilter', function () {
      var t = window.location.search.toQueryParams();
      delete t['details'];
      delete t['filterType'];
      delete t['filter'];
      t['showAll'] = '';
      window.location.search = Object.toQueryString(t);

      $('notificationDetailsContainer').refresh(null, '', function () {
        BS.NotificationRuleForm.enableSaving();

        var t = window.location.search.toQueryParams();
        t['showAll']='';
        window.history.pushState({}, "", window['base_uri'] + '/profile.html?' + Object.toQueryString(t));
      });
    });

    $j('#hideAll').on('click', function() {
      $j('#allRulesBlock').hide();
      $j('#showAll').show();
      $j('#hideAll').hide();


      var t = window.location.search.toQueryParams();
      delete t['showAll'];
      window.history.pushState({}, "", window['base_uri'] + '/profile.html?' + Object.toQueryString(t));
    });

    $j('#showAll').on('click', function () {
      $j('#allRulesBlock').show();
      $j('#showAll').hide();
      $j('#hideAll').show();

      var t = window.location.search.toQueryParams();
      t['showAll']='';
      window.history.pushState({}, "", window['base_uri'] + '/profile.html?' + Object.toQueryString(t));
    });

    <%--$j(document).on('click', '#addUnsubscribeRuleButton', function() {--%>
    <%--BS.NotificationRuleForm.addUnsubscribeRule('${editRuleUrl}');--%>
    <%--});--%>
  });
</script>