import alt from '../alt';

class SchedulingFilterActions {
  constructor() {
    this.generateActions(
      'changeUserFilter',
      'changeRoleFilter',
      'changeSkillFilter',
      'showAll',
      'showJuniorsAndInterns',
      'showToRotate',
      'showInternals',
      'showInRotation',
      'showInCommercialProjectsWithDueDate',
      'showBooked',
      'showUnavailable',
      'showNotScheduled'
    )
  }
}

export default alt.createActions(SchedulingFilterActions);
