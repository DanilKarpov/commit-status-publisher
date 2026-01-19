<%@ include file="include-internal.jsp" %>
<%--@elvariable id="currentUser" type="jetbrains.buildServer.users.SUser"--%>
<%--@elvariable id="refreshableId" type="java.lang.String"--%>
<%--@elvariable id="refreshJS" type="java.lang.String"--%>
<%--@elvariable id="buildTypesStatusMap" type="java.util.Map"--%>
<%--@elvariable id="notTriggeredText" type="java.lang.String"--%>
<c:if test="${empty refreshJS}">
  <c:set var="refreshJS" value="$('${refreshableId}').refresh_delayed()"/>
</c:if>
<div class="hideSuccessfulBlock">
  <profile:booleanPropertyCheckbox controlId="${refreshableId}_hideSuccessful" propertyKey="changePage_hideSuccessful" labelText="Hide successfully finished and not triggered configurations" afterComplete="${refreshJS}" progress="${refreshableId}_hideSuccessfulProgress"/>
  <span style="display: inline-block; width: 24px;">
    <forms:progressRing id="${refreshableId}_hideSuccessfulProgress" style="display: none;" progressTitle="" className="progressRingInline"/>
  </span>

  <c:if test="${not empty buildTypesStatusMap}">
  <profile:booleanPropertyCheckbox controlId="${refreshableId}_showHierarchy" propertyKey="build.deployments.block.hierarchicalView" labelText="Show projects hierarchy" afterComplete="${refreshJS}" progress="${refreshableId}_showHierarchyProgress"/>
  <span style="display: inline-block; width: 24px;">
    <forms:progressRing id="${refreshableId}_showHierarchyProgress" style="display: none;" progressTitle="" className="progressRingInline"/>
  </span>
  </c:if>
</div>

<bs:buildPromotionsTable buildTypePromotionsMap="${buildTypesStatusMap}" showHierarchy="${ufn:booleanPropertyValue(currentUser, 'build.deployments.block.hierarchicalView')}" refreshJS="${refreshJS}" notTriggeredText="${notTriggeredText}">
  <jsp:attribute name="beforeBuildTypeNameHTML">
    <c:if test="${empty build or not build.finished}">
    <et:subscribeOnBuildTypeEvents buildTypeId="${buildType.buildTypeId}">
      <jsp:attribute name="eventNames">
        BUILD_STARTED
        BUILD_FINISHED
        BUILD_INTERRUPTED
        BUILD_TYPE_REMOVED_FROM_QUEUE
      </jsp:attribute>
      <jsp:attribute name="eventHandler">
        ${refreshJS}
      </jsp:attribute>
    </et:subscribeOnBuildTypeEvents>
    </c:if>
  </jsp:attribute>
</bs:buildPromotionsTable>
